# frozen_string_literal: true

module MyErp
  # Thread-safe LRU cache of tenant Sequel::Database handles.
  #
  # Holding one open connection per tenant would blow past the file-descriptor
  # budget of a 1 GB VPS, so at most `max` (default 30) databases stay open and
  # the least-recently-used handle is disconnected on eviction.
  #
  #   DB.with_tenant("acme") { |db| ... }   # scoped, thread-local tenant id
  class TenantManager
    DEFAULT_MAX = 30

    Entry = Struct.new(:id, :connection)

    class << self
      def instance
        @instance ||= new
      end

      def reset!
        @instance&.close_all
        @instance = nil
      end
    end

    attr_reader :max

    # +connector+ (or a block) is injectable for specs: ->(id) { db }.
    def initialize(max: Integer(ENV.fetch("TENANT_CACHE_SIZE", DEFAULT_MAX)), connector: nil, &block)
      raise ArgumentError, "max must be positive" unless max.positive?

      @max = max
      @mutex = Mutex.new
      @entries = {}
      @connector = connector || block || ->(id) { MyErp::DB.connect(MyErp::DB.tenant_path(id)) }
    end

    def fetch(id)
      validate!(id)

      hit = @mutex.synchronize { touch(id) }
      return hit.connection if hit

      fresh = @connector.call(id)
      stale = []

      entry = @mutex.synchronize do
        if (existing = touch(id))
          # Another thread opened the same tenant while we were connecting.
          stale << fresh
          existing
        else
          new_entry = Entry.new(id, fresh)
          @entries[id] = new_entry

          while @entries.size > @max
            _victim_id, victim = @entries.shift
            stale << victim.connection
          end

          new_entry
        end
      end

      close_connections(stale)
      entry.connection
    end

    def with_tenant(id)
      previous = Thread.current[:myerp_tenant_id]
      Thread.current[:myerp_tenant_id] = id
      yield fetch(id)
    ensure
      Thread.current[:myerp_tenant_id] = previous
    end

    def current_tenant_id
      Thread.current[:myerp_tenant_id]
    end

    def size
      @mutex.synchronize { @entries.size }
    end

    def ids
      @mutex.synchronize { @entries.keys }
    end

    def open?(id)
      @mutex.synchronize { @entries.key?(id) }
    end

    def close_all
      entries = @mutex.synchronize do
        victims = @entries.values
        @entries.clear
        victims
      end

      close_connections(entries.map(&:connection))
      nil
    end

    private

    # Must be called with @mutex held. Promotes +id+ to most-recently-used.
    def touch(id)
      entry = @entries.delete(id)
      @entries[id] = entry if entry
      entry
    end

    def close_connections(connections)
      connections.uniq(&:object_id).each do |connection|
        connection.disconnect
      rescue StandardError => e
        warn "[MyErp::TenantManager] disconnect failed: #{e.class}: #{e.message}"
      end
    end

    def validate!(id)
      raise ArgumentError, "invalid tenant id: #{id.inspect}" unless MyErp::DB.tenant_id?(id)
    end
  end
end
