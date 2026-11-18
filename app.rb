# frozen_string_literal: true

require_relative "config/boot"
require "roda"
require_relative "lib/roda/plugins/render_phlex"
require_relative "config/rodauth"

class MyErp::App < Roda
  plugin :sessions,
         secret: MyErp::SESSION_SECRET,
         cookie_options: {
           httponly: true,
           same_site: :lax,
           secure: MyErp::ENV_NAME == "production"
         }

  plugin :route_csrf
  plugin :flash
  plugin :public
  plugin :json, serializer: ->(object) { Oj.dump(object) }
  plugin :json_parser, content_type_regexp: %r{\Aapplication/(?:vnd\.api\+)?json\b}i
  plugin :all_verbs
  plugin :typecast_params
  plugin :Integer_matcher_max
  plugin :hash_branches
  plugin :render_phlex
  plugin :default_headers,
         "X-Content-Type-Options" => "nosniff",
         "X-Frame-Options" => "DENY",
         "Referrer-Policy" => "same-origin"

  # Dashboard/session auth. Tilt is never loaded: views are Phlex overrides.
  MyErp::WebAuth.install(self)

  plugin :error_handler do |error|
    status, title, message =
      case error
      when Roda::RodaPlugins::RouteCsrf::InvalidToken
        [403, "Forbidden", "Invalid or missing CSRF token."]
      else
        env["rack.errors"]&.puts("[MyErp] #{error.class}: #{error.message}")
        env["rack.errors"]&.puts(error.backtrace&.first(20)&.join("\n"))
        [500, "Internal Server Error", "Something went wrong."]
      end

    error_response(status, title, message)
  end

  plugin :not_found do
    error_response(404, "Not Found", "The page you requested does not exist.")
  end

  route do |r|
    r.rodauth

    r.get "health" do
      db_ok = begin
        MyErp::DB.main.get(Sequel.lit("1")) == 1
      rescue Sequel::Error
        false
      end

      response.status = db_ok ? 200 : 503
      {
        "status" => db_ok ? "ok" : "degraded",
        "database" => db_ok ? "ok" : "error"
      }
    end

    r.on "api" do
      r.on "v1" do
        r.on "auth" do
          r.run MyErp::ApiAuth
        end

        r.hash_branches(:api_v1)
      end
    end

    r.is "dashboard" do
      r.redirect "/login" unless rodauth.logged_in?

      r.get do
        render_phlex(MyErp::Views::Dashboard::Home.new)
      end
    end

    r.on "dashboard" do
      r.redirect "/login" unless rodauth.logged_in?

      r.hash_branches(:dashboard)
    end
  end

  hash_branch(:api_v1, "ping") do |r|
    r.get do
      { "status" => "ok" }
    end
  end

  private

  def error_response(status, title, message)
    response.status = status

    if request.path.start_with?("/api/")
      response["Content-Type"] = "application/json"
      Oj.dump(
        "error" => title.downcase.tr(" ", "_"),
        "message" => message
      )
    else
      response["Content-Type"] = "text/html; charset=utf-8"
      render_phlex(
        MyErp::Views::ErrorPage.new(status: status, title: title, message: message)
      )
    end
  end
end

# Rodauth's default templates are Tilt; with render: false the two views this
# configuration can reach are rendered with Phlex instead.
MyErp::App.rodauth.class_eval do
  def login_view
    MyErp::Views::Auth::Login.new(
      csrf_token_tag: csrf_tag(login_path)
    ).call
  end

  def create_account_view
    MyErp::Views::Auth::CreateAccount.new(
      csrf_token_tag: csrf_tag(create_account_path)
    ).call
  end
end
