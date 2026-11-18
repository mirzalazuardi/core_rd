# frozen_string_literal: true

require "spec_helper"
require "jwt"

RSpec.describe "JWT login", type: :request do
  let(:email) { "api@example.com" }
  let(:password) { AuthHelper::DEFAULT_PASSWORD }
  let!(:account_id) { create_account!(email: email, password: password) }

  def login(password_value = password)
    # Oj.dump serializes symbol keys as ":login"; Rodauth reads "login".
    post "/api/v1/auth/login",
         Oj.dump("login" => email, "password" => password_value),
         json_headers
  end

  it "issues a verifiable HS256 access token and a refresh token" do
    login

    expect(last_response.status).to eq(200)

    body = json_body
    token = body["access_token"] || last_response.headers["authorization"]
    expect(token).to be_a(String)
    expect(body["refresh_token"]).to be_a(String)

    payload, header = JWT.decode(token, MyErp::JWT_SECRET, true, algorithm: "HS256")

    expect(header["alg"]).to eq("HS256")
    expect(payload["account_id"]).to eq(account_id)
  end

  it "does not verify with a different secret" do
    login
    token = json_body["access_token"] || last_response.headers["authorization"]

    expect do
      JWT.decode(token, "wrong-secret", true, algorithm: "HS256")
    end.to raise_error(JWT::VerificationError)
  end

  it "rejects invalid credentials with JSON 401" do
    login("wrong-password")

    expect(last_response.status).to eq(401)
    expect(last_response.headers["content-type"]).to include("application/json")
    expect(json_body).to include("error")
  end
end
