module Api
  module V1
    class OpenapiController < ApplicationController
      allow_unauthenticated_access only: :show

      def show
        spec_path = Rails.root.join("docs/openapi.yml")
        spec = YAML.safe_load_file(spec_path)
        render json: spec
      end
    end
  end
end
