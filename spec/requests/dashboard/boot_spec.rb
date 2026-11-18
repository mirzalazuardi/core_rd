# frozen_string_literal: true

require "spec_helper"

RSpec.describe "Dashboard boot", type: :request do
  it "redirects an anonymous GET /dashboard to /login" do
    get "/dashboard"

    expect(last_response.status).to eq(302)
    expect(location_path).to eq("/login")
  end

  it "redirects anonymous dashboard subpaths to /login" do
    get "/dashboard/reports"

    expect(last_response.status).to eq(302)
    expect(location_path).to eq("/login")
  end
end
