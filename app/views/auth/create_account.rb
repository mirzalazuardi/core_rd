# frozen_string_literal: true

module MyErp
  module Views
    module Auth
      class CreateAccount < Phlex::HTML
        def initialize(csrf_token_tag:)
          @csrf_token_tag = csrf_token_tag
        end

        def view_template
          doctype
          html do
            head do
              meta(charset: "utf-8")
              meta(name: "viewport", content: "width=device-width, initial-scale=1")
              title { "Create account — MyErp" }
            end
            body do
              main do
                h1 { "Create account" }
                form(action: "/create-account", method: "post") do
                  raw safe(@csrf_token_tag)
                  label(for: "login") { "Email" }
                  input(type: "email", id: "login", name: "login", required: true,
                        autocomplete: "username")
                  label(for: "password") { "Password" }
                  input(type: "password", id: "password", name: "password", required: true,
                        autocomplete: "new-password")
                  button(type: "submit") { "Create account" }
                end
              end
            end
          end
        end
      end
    end
  end
end
