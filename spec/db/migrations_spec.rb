# frozen_string_literal: true

require "spec_helper"
require "tmpdir"

RSpec.describe "Database migrations" do
  around do |example|
    Dir.mktmpdir("myerp-migrations") do |dir|
      @dir = dir
      example.run
    end
  end

  def new_db(name)
    MyErp::DB.connect(File.join(@dir, "#{name}.sqlite3"))
  end

  it "applies the main Rodauth schema and is idempotent" do
    db = new_db("main")

    expect(MyErp::DB.migrate!(db, MyErp::DB::MAIN_MIGRATIONS)).to eq(:ok)
    expect(db.tables).to include(:accounts, :account_password_hashes, :account_jwt_refresh_keys)
    expect(db[:accounts].columns).to include(:email, :status_id)
    expect(db[:account_password_hashes].columns).to include(:password_hash)

    expect(MyErp::DB.migrate!(db, MyErp::DB::MAIN_MIGRATIONS)).to eq(:ok)
    expect(db[:schema_info].get(:version)).to eq(1)
  ensure
    db&.disconnect
  end

  it "treats an empty migration directory as a valid no-op" do
    empty_dir = File.join(@dir, "empty")
    Dir.mkdir(empty_dir)
    db = new_db("empty")

    expect(MyErp::DB.migrate!(db, empty_dir)).to eq(:empty)
    expect(db.table_exists?(:schema_info)).to be(false)
  ensure
    db&.disconnect
  end

  it "applies the tenant migrations to a tenant database" do
    db = new_db("tenant")

    expect(MyErp::DB.migrate!(db, MyErp::DB::TENANT_MIGRATIONS)).to eq(:empty)
    expect(MyErp::DB.tenant_ids).not_to include("tenant")
  ensure
    db&.disconnect
  end

  it "enforces the SQLite PRAGMAs on every new connection" do
    db = new_db("pragmas")
    pragma = ->(name) { db.fetch("PRAGMA #{name}").first.values.first }

    expect(pragma.call("journal_mode")).to eq("wal")
    expect(pragma.call("foreign_keys")).to eq(1)
    expect(pragma.call("busy_timeout")).to eq(5000)
    expect(pragma.call("temp_store")).to eq(2)
    expect(pragma.call("synchronous")).to eq(1)
  ensure
    db&.disconnect
  end
end
