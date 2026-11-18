# frozen_string_literal: true

module MyErp
  module Views
    module Auth
      class Login < Phlex::HTML
        def initialize(csrf_token_tag:)
          @csrf_token_tag = csrf_token_tag
        end

        def view_template
          doctype
          html do
            head do
              meta(charset: "utf-8")
              meta(name: "viewport", content: "width=device-width, initial-scale=1")
              title { "Sign in — MyErp" }
            end
            body do
              main do
                h1 { "Sign in" }
                form(action: "/login", method: "post") do
                  raw safe(@csrf_token_tag)
                  label(for: "login") { "Email" }
                  input(type: "email", id: "login", name: "login", required: true,
                        autocomplete: "username")
                  label(for: "password") { "Password" }
                  input(type: "password", id: "password", name: "password", required: true,
                        autocomplete: "current-password")
                  button(type: "submit") { "Sign in" }
                end
              end
            end
          end
        end
      end
    end
  end
end
