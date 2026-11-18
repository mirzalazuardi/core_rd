# frozen_string_literal: true

require "spec_helper"
require "tmpdir"

RSpec.describe MyErp::TenantManager do
  around do |example|
    Dir.mktmpdir("myerp-tenant-manager") do |dir|
      @dir = dir
      example.run
    end
  end

  def connect(id)
    MyErp::DB.connect(File.join(@dir, "#{id}.sqlite3"))
  end

  # Adds an observable disconnect hook without changing Sequel behaviour.
  def with_disconnect_spy(db)
    spy = Module.new do
      def disconnect_count
        @disconnect_count ||= 0
      end

      def disconnect
        @disconnect_count = disconnect_count + 1
        super
      end
    end
    db.singleton_class.prepend(spy)
    db
  end

  subject(:manager) { described_class.new(max: 3) { |id| connect(id) } }

  it "keeps at most max tenant databases open" do
    10.times { |i| manager.fetch("tenant#{i}") }

    expect(manager.size).to eq(3)
    expect(manager.ids).to eq(%w[tenant7 tenant8 tenant9])
  end

  it "evicts the least recently used tenant and disconnects its handle" do
    connections = {}
    cache = described_class.new(max: 2) do |id|
      connections[id] = with_disconnect_spy(connect(id))
    end

    cache.fetch("a")
    cache.fetch("b")
    cache.fetch("a") # refresh: "a" is now most recently used
    cache.fetch("c") # evicts "b"

    expect(cache.ids).to include("a", "c")
    expect(connections["b"].disconnect_count).to eq(1)
    expect(connections["a"].disconnect_count).to eq(0)
  end

  it "releases the underlying SQLite connections on eviction (no fd leak)" do
    cache = described_class.new(max: 1) { |id| connect(id) }

    first = cache.fetch("first")
    expect(first.pool.size).to eq(1)

    cache.fetch("second")

    # Sequel closed the evicted handle: the pool no longer holds connections.
    expect(first.pool.size).to eq(0)
    expect(cache.size).to eq(1)
  end

  it "disconnects every handle on close_all" do
    connections = {}
    cache = described_class.new(max: 5) do |id|
      connections[id] = with_disconnect_spy(connect(id))
    end

    cache.fetch("a")
    cache.fetch("b")
    cache.close_all

    expect(cache.size).to eq(0)
    expect(connections.values.map(&:disconnect_count)).to eq([1, 1])
  end

  it "sets and restores the thread-local tenant id" do
    outer = manager.with_tenant("acme") do
      expect(manager.current_tenant_id).to eq("acme")
      manager.with_tenant("globex") { manager.current_tenant_id }
    end

    expect(outer).to eq("globex")
    expect(manager.current_tenant_id).to be_nil
  end

  it "rejects tenant ids that could escape the tenants directory" do
    expect { manager.fetch("../main") }.to raise_error(ArgumentError)
    expect { manager.fetch("a/b") }.to raise_error(ArgumentError)
    expect { manager.fetch("A") }.to raise_error(ArgumentError)
  end

  it "returns the same handle for a cached tenant" do
    expect(manager.fetch("acme")).to be(manager.fetch("acme"))
  end

  describe "SQLite PRAGMA profile" do
    def pragma(db, name)
      db.fetch("PRAGMA #{name}").first.values.first
    end

    def expect_pragmas(db, label)
      expect(pragma(db, "journal_mode")).to eq("wal"), "#{label}: journal_mode"
      expect(pragma(db, "synchronous")).to eq(1), "#{label}: synchronous"
      expect(pragma(db, "foreign_keys")).to eq(1), "#{label}: foreign_keys"
      expect(pragma(db, "busy_timeout")).to eq(5000), "#{label}: busy_timeout"
      expect(pragma(db, "temp_store")).to eq(2), "#{label}: temp_store"
    end

    it "is applied to the main, queue, and tenant connections" do
      expect_pragmas(MyErp::DB.main, "main")
      expect_pragmas(MyErp::DB.queue, "queue")
      expect_pragmas(tenant_db, "tenant")
    end

    it "is applied to every connection opened by the manager" do
      expect_pragmas(manager.fetch("pragma-tenant"), "new tenant")
    end
  end
end
