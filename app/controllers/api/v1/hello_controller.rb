module Api
  module V1
    class HelloController < ApplicationController
      def index
        render json: { message: "Gym Ghost says hello" }
      end
    end
  end
end
