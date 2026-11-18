# frozen_string_literal: true

source "https://rubygems.org"

ruby ">= 3.3.0"

# --- Web + persistence -------------------------------------------------------
gem "roda", ">= 3.100"
gem "sequel", ">= 5.100"
gem "sqlite3", "~> 1.7"
gem "puma", ">= 6.6"
gem "rack", ">= 3.0"

# --- Presentation / API contract --------------------------------------------
gem "phlex", "~> 2.4"
gem "pagy"
gem "alba", ">= 3.6"
gem "oj", ">= 3.16"

# --- Auth & authorization ----------------------------------------------------
gem "rodauth", ">= 2.40"
gem "jwt", ">= 2.7"
gem "bcrypt", ">= 3.1"
gem "action_policy", "~> 0.7"

# --- Background jobs ---------------------------------------------------------
# `litejob` (not the `litestack` meta-gem): litestack 0.4.x depends on
# erubi + tilt, both forbidden by CLAUDE.md. Litejob is the only component
# this app needs and runs on db/queue.sqlite3.
gem "litejob", "~> 0.2"

# --- Platform ----------------------------------------------------------------
gem "dotenv", ">= 3.0"
gem "zeitwerk", ">= 2.7"
gem "rake", ">= 13.0"

group :development do
  gem "rack-unreloader", ">= 2.0"
end

group :test do
  gem "rspec", "~> 3.13"
  gem "rack-test", "~> 2.2"
  gem "database_cleaner-sequel", "~> 2.0"
  gem "ffaker", "~> 2.23"
  gem "timecop", "~> 0.9"
  gem "simplecov", "~> 0.22"
end
