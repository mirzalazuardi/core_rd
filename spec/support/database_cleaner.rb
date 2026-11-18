# frozen_string_literal: true

# `database_cleaner/sequel` registers a default `:sequel` cleaner without a
# database; with several Sequel databases active that cleaner cannot resolve
# which db to use, so drop it and register each database explicitly.
DatabaseCleaner.cleaners.clear

# Tenant databases are opened through TenantManager, so the spec tenant must
# exist before it can be registered. Its migrations directory is empty today.
SPEC_TENANT_DB = MyErp::DB.tenant(SPEC_TENANT_ID)
MyErp::DB.migrate!(SPEC_TENANT_DB, MyErp::DB::TENANT_MIGRATIONS)

[
  MyErp::DB.main,
  MyErp::DB.queue,
  SPEC_TENANT_DB
].each do |db|
  DatabaseCleaner[:sequel, db: db].strategy = :transaction
end

RSpec.configure do |config|
  config.before(:suite) do
    DatabaseCleaner.clean_with(:truncation)
    # Scratch tables used only by spec/support/database_cleaner_spec.rb to
    # prove examples are isolated. Not migrations, not application schema.
    [MyErp::DB.main, SPEC_TENANT_DB].each do |db|
      db.create_table?(:cleaner_probe) { String :value }
      db[:cleaner_probe].delete
    end
  end

  config.before(:each) do
    DatabaseCleaner.start
  end

  config.after(:each) do
    DatabaseCleaner.clean
  end
end
