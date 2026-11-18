# frozen_string_literal: true

require "rack/test"

module RequestHelper
  include Rack::Test::Methods

  def app
    MyErp::App
  end

  def json_body
    JSON.parse(last_response.body)
  end
end
