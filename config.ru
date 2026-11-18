# frozen_string_literal: true

require_relative "config/boot"

if ENV.fetch("RACK_ENV", "development") == "development"
  require "rack/unreloader"

  Unreloader = Rack::Unreloader.new(
    subclasses: %w[Roda],
    handle_reload_errors: true
  ) { MyErp::App }

  Unreloader.require "./app.rb"
  run Unreloader
else
  require_relative "app"
  run MyErp::App
end
