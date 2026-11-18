# frozen_string_literal: true

require "spec_helper"

RSpec.describe "GET /health", type: :request do
  it "returns 200 with JSON when the app and main database are up" do
    get "/health"

    expect(last_response.status).to eq(200)
    expect(last_response.headers["content-type"]).to include("application/json")
    expect(json_body).to eq("status" => "ok", "database" => "ok")
  end

  it "does not leak framework or database details" do
    get "/health"

    expect(last_response.body).not_to match(/sqlite|sequel|roda/i)
  end
end
