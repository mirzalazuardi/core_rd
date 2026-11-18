# frozen_string_literal: true

require "spec_helper"

RSpec.describe "GET /api/v1/ping", type: :request do
  it "returns 200 with a JSON payload without authentication" do
    get "/api/v1/ping"

    expect(last_response.status).to eq(200)
    expect(last_response.headers["content-type"]).to include("application/json")
    expect(json_body).to eq("status" => "ok")
  end

  it "returns JSON 404 for an unknown API route" do
    get "/api/v1/nope"

    expect(last_response.status).to eq(404)
    expect(last_response.headers["content-type"]).to include("application/json")
    expect(json_body).to include("error" => "not_found")
  end
end
