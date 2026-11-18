# frozen_string_literal: true

require "bundler/setup"

ENV["RACK_ENV"] ||= "development"

require "dotenv"
Dotenv.load(".env") unless ENV["RACK_ENV"] == "production"

require "sequel"
require "sqlite3"
require "oj"
require "phlex"
require "zeitwerk"

module MyErp
  ROOT = File.expand_path("..", __dir__)
  ENV_NAME = ENV.fetch("RACK_ENV", "development")

  class << self
    def root(*parts)
      File.join(ROOT, *parts)
    end

    def loader
      @loader ||= Zeitwerk::Loader.new.tap do |loader|
        loader.push_dir(root("app"), namespace: MyErp)
        loader.setup
      end
    end

    def eager_load!
      loader.eager_load
    end
  end
end

MyErp.loader

require_relative "tenant_manager"
require_relative "database"
