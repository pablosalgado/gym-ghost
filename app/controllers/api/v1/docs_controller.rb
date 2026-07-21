module Api
  module V1
    class DocsController < ApplicationController
      allow_unauthenticated_access only: :show

      def show
        render html: swagger_ui_html.html_safe
      end

      private

      def swagger_ui_html
        <<~HTML
          <!DOCTYPE html>
          <html lang="en">
          <head>
            <meta charset="UTF-8">
            <meta name="viewport" content="width=device-width, initial-scale=1.0">
            <title>Gym Ghost API — Swagger UI</title>
            <link rel="stylesheet" href="https://unpkg.com/swagger-ui-dist@5/swagger-ui.css">
          </head>
          <body>
            <div id="swagger-ui"></div>
            <script src="https://unpkg.com/swagger-ui-dist@5/swagger-ui-bundle.js" crossorigin></script>
            <script>
              SwaggerUIBundle({
                url: "/api/v1/openapi.json",
                dom_id: "#swagger-ui",
              });
            </script>
          </body>
          </html>
        HTML
      end
    end
  end
end
