# frozen_string_literal: true

require "spec_helper"

RSpec.describe "Session login", type: :request do
  let(:email) { "owner@example.com" }
  let(:password) { AuthHelper::DEFAULT_PASSWORD }

  before { create_account!(email: email, password: password) }

  it "renders the Phlex login form with a CSRF token" do
    get "/login"

    expect(last_response.status).to eq(200)
    expect(last_response.headers["content-type"]).to include("text/html")
    expect(last_response.body).to include("Sign in")
    expect(csrf_token_from(last_response.body)).not_to be_nil
  end

  it "rejects a POST /login without a CSRF token" do
    post "/login", { login: email, password: password }

    expect(last_response.status).to eq(403)
    expect(last_response.body).to include("Forbidden")
  end

  it "logs in with a valid CSRF token and reaches the dashboard" do
    get "/login"
    token = csrf_token_from(last_response.body)

    post "/login", { login: email, password: password, _csrf: token }

    expect(last_response.status).to eq(302)
    expect(location_path).to eq("/dashboard")

    get "/dashboard"

    expect(last_response.status).to eq(200)
    expect(last_response.body).to include("Dashboard")
  end

  it "rejects invalid credentials even with a valid CSRF token" do
    get "/login"
    token = csrf_token_from(last_response.body)

    post "/login", { login: email, password: "wrong-password", _csrf: token }

    expect(last_response.status).to eq(401)
    expect(last_response.body).to include("Sign in")
  end
end
