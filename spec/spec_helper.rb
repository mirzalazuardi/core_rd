# frozen_string_literal: true

require "fileutils"

ENV["RACK_ENV"] = "test"
# Specs always use a throwaway directory; never honour DB_DIR from the shell.
ENV["DB_DIR"] = File.expand_path("../tmp/test-db", __dir__)

# Each suite starts from a clean SQLite directory so migration/cleaner specs
# are deterministic.
FileUtils.rm_rf(ENV.fetch("DB_DIR"))
FileUtils.mkdir_p(ENV.fetch("DB_DIR"))

require "simplecov"
SimpleCov.start do
  add_filter "/spec/"
  add_filter "/tmp/"
  # Process/entrypoint files are not exercised by RSpec.
  add_filter "/config/puma.rb"
  add_filter "/config.ru"
  enable_coverage :branch
end

require "json"
require "rack/test"
require "ffaker"
require "timecop"
require "database_cleaner/sequel"

require_relative "../config/boot"
require_relative "../app"

# Phase 1 main schema (Rodauth). Tenant migrations remain empty for now.
MyErp::DB.migrate!(MyErp::DB.main, MyErp::DB::MAIN_MIGRATIONS)

# Shared with spec/support/*.rb
SPEC_TENANT_ID = "spec-tenant"

Dir[File.join(__dir__, "support", "**", "*.rb")].sort.each do |file|
  require file unless file.end_with?("_spec.rb")
end

RSpec.configure do |config|
  config.expect_with :rspec do |expectations|
    expectations.syntax = :expect
  end

  config.mock_with :rspec do |mocks|
    mocks.verify_partial_doubles = true
  end

  config.order = :random
  Kernel.srand config.seed

  config.include TenantHelper
  config.include AuthHelper
  config.include RequestHelper, type: :request
end
