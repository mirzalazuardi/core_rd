# frozen_string_literal: true

module MyErp
  module Views
    module Dashboard
      class Home < Phlex::HTML
        def view_template
          doctype
          html do
            head do
              meta(charset: "utf-8")
              meta(name: "viewport", content: "width=device-width, initial-scale=1")
              title { "Dashboard — MyErp" }
            end
            body do
              main do
                h1 { "Dashboard" }
                p { "Core infrastructure is online." }
              end
            end
          end
        end
      end
    end
  end
end
