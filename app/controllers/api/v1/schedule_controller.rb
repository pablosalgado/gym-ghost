module Api
  module V1
    class ScheduleController < ApplicationController
      def index
        render json: { schedule: [] }
      end
    end
  end
end
