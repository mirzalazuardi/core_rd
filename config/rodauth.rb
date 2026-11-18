# frozen_string_literal: true

require_relative "boot"
require "securerandom"
require "rodauth"

module MyErp
  class << self
    # Secrets must be provided in production; dev/test fall back to random
    # values so the app boots without a .env file.
    def secret(name)
      value = ENV[name]
      return value if value && !value.empty?

      if ENV_NAME == "production"
        raise "#{name} must be set in production"
      end

      SecureRandom.hex(64)
    end
  end

  SESSION_SECRET = secret("SESSION_SECRET")
  JWT_SECRET = secret("JWT_SECRET")
  HMAC_SECRET = secret("HMAC_SECRET")
end

# Rodauth resolves its database via Sequel::DATABASES.first, so main.sqlite3
# must be the first Sequel database opened by the process.
MyErp::DB.main

module MyErp
  # Session/cookie Rodauth configuration for the dashboard. Rodauth hooks into
  # the Roda class, so MyErp::App installs this after sessions/route_csrf/flash.
  module WebAuth
    def self.install(app)
      app.plugin :rodauth, render: false do
        enable :login, :logout, :create_account

        login_redirect "/dashboard"
        logout_redirect "/login"
        create_account_redirect "/dashboard"

        require_login_confirmation? false
        require_password_confirmation? false

        already_logged_in do
          redirect "/dashboard"
        end
      end
    end
  end

  # JWT-only Rodauth configuration, mounted at /api/v1/auth by MyErp::App.
  # Same main.sqlite3 accounts as the dashboard session configuration.
  class ApiAuth < Roda
    # Load first so Rodauth's own json_parser load reuses this safe regexp.
    plugin :json_parser, content_type_regexp: %r{\Aapplication/(?:vnd\.api\+)?json\b}i

    plugin :rodauth,
           name: :api,
           json: :only,
           csrf: false,
           render: false,
           flash: false do
      enable :login, :logout, :create_account, :jwt, :jwt_refresh

      jwt_secret MyErp::JWT_SECRET
      hmac_secret MyErp::HMAC_SECRET

      require_login_confirmation? false
      require_password_confirmation? false

      already_logged_in do
        redirect "/api/v1/ping"
      end

      login_redirect "/api/v1/ping"
      logout_redirect "/api/v1/ping"
      create_account_redirect "/api/v1/ping"
    end

    route do |r|
      r.rodauth(:api)
    end
  end
end

# Rodauth only computes refresh-token deadlines for MySQL
# (`set_deadline_values?`); SQLite would insert NULL into a NOT NULL column.
MyErp::ApiAuth.rodauth(:api).class_eval do
  def set_deadline_value(hash, column, interval)
    super
    hash[column] ||= Time.now + (interval.fetch(:days, 0).to_i * 86_400)
  end
end
