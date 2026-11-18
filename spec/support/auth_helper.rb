# frozen_string_literal: true

require "bcrypt"
require "uri"

module AuthHelper
  DEFAULT_PASSWORD = "Sup3rSecret!2026"

  def auth_headers(token)
    { "HTTP_AUTHORIZATION" => "Bearer #{token}" }
  end

  def json_headers(extra = {})
    { "CONTENT_TYPE" => "application/json", "HTTP_ACCEPT" => "application/json" }.merge(extra)
  end

  # Creates a verified account directly in main.sqlite3. Account creation via
  # Rodauth needs CSRF/email flows that are irrelevant to the auth specs.
  def create_account!(email: "owner@example.com", password: DEFAULT_PASSWORD)
    db = MyErp::DB.main
    id = db[:accounts].insert(email: email, status_id: 2)
    db[:account_password_hashes].insert(
      id: id,
      password_hash: BCrypt::Password.create(password)
    )
    id
  end

  # route_csrf emits a hidden input; extract its value without adding Nokogiri.
  def csrf_token_from(html)
    tag = html.scan(/<input\b[^>]*>/).find { |input| input.include?('name="_csrf"') }
    tag && tag[/value="([^"]+)"/, 1]
  end

  def location_path
    URI.parse(last_response.headers.fetch("location")).path
  end
end
