# frozen_string_literal: true

module MyErp
  module Views
    class ErrorPage < Phlex::HTML
      def initialize(status:, title:, message:)
        @status = status
        @title = title
        @message = message
      end

      def view_template
        doctype
        html do
          head do
            meta(charset: "utf-8")
            meta(name: "viewport", content: "width=device-width, initial-scale=1")
            title { "#{@status} #{@title} — MyErp" }
          end
          body do
            main do
              h1 { "#{@status} #{@title}" }
              p { @message }
            end
          end
        end
      end
    end
  end
end
