# frozen_string_literal: true

require "fileutils"

module MyErp
  # Connection factory + migration entry point for the three database classes:
  #   db/main.sqlite3          global users / tenants / memberships / Rodauth
  #   db/queue.sqlite3         Litejob only
  #   db/tenants/<id>.sqlite3  isolated ERP data
  #
  # Tenant databases are never cached here; they are handed to TenantManager.
  module DB
    # SQLite files live under DB_DIR (throwaway directory in specs), while
    # migrations always ship with the code under <root>/db/migrate.
    DIR = File.expand_path(ENV.fetch("DB_DIR", "db"), MyErp::ROOT)

    MAIN_MIGRATIONS = File.join(MyErp::ROOT, "db", "migrate", "main").freeze
    TENANT_MIGRATIONS = File.join(MyErp::ROOT, "db", "migrate", "tenant").freeze

    # PRAGMA profile applied to every physical connection:
    #   journal_mode=WAL, synchronous=NORMAL, busy_timeout=5000,
    #   foreign_keys=ON, temp_store=MEMORY.
    # Sequel's SQLite adapter maps all but journal_mode to connection options;
    # WAL is set in after_connect because it is a persistent database property.
    class << self
      def connect(path)
        FileUtils.mkdir_p(File.dirname(path))

        db = Sequel.sqlite(
          path,
          timeout: 5000, # busy_timeout, milliseconds (Sequel default is 5000)
          foreign_keys: true,
          synchronous: :normal,
          temp_store: :memory,
          after_connect: ->(connection) { connection.execute("PRAGMA journal_mode = WAL") }
        )
        db.test_connection
        db
      end

      def main
        @main ||= connect(File.join(DIR, "main.sqlite3"))
      end

      def queue
        @queue ||= connect(File.join(DIR, "queue.sqlite3"))
      end

      def tenant_path(id)
        raise ArgumentError, "invalid tenant id: #{id.inspect}" unless tenant_id?(id)

        File.join(DIR, "tenants", "#{id}.sqlite3")
      end

      def tenant_ids
        Dir.glob(File.join(DIR, "tenants", "*.sqlite3"))
           .map { |path| File.basename(path, ".sqlite3") }
           .sort
      end

      def tenant(id)
        TenantManager.instance.fetch(id)
      end

      def with_tenant(id, &block)
        TenantManager.instance.with_tenant(id, &block)
      end

      # Runs pending migrations for +dir+. Empty migration directories are a
      # valid state early in the project (Phase 0.5) and must not raise.
      def migrate!(db, dir)
        return :empty if Dir.glob(File.join(dir, "*.rb")).empty?

        Sequel.extension :migration
        Sequel::Migrator.run(db, dir)
        :ok
      end

      def close!
        [@main, @queue].compact.each(&:disconnect)
        @main = @queue = nil
        TenantManager.instance.close_all
      end

      def tenant_id?(id)
        id.is_a?(String) && id.match?(/\A[a-z0-9][a-z0-9_-]{0,63}\z/)
      end
    end
  end
end
