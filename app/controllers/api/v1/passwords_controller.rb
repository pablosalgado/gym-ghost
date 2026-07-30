module Api
  module V1
    class PasswordsController < ApplicationController
      def update
        unless current_user.authenticate(password_params[:current_password])
          render json: {
            errors: [ { status: 401, title: "Unauthorized", detail: "Current password is incorrect" } ]
          }, status: :unauthorized
          return
        end

        current_user.update!(password_params.except(:current_password))
        head :ok
      rescue ActionController::ParameterMissing
        render json: {
          errors: [ { status: 422, title: "Validation Failed", detail: "Current password, password, and password confirmation are required" } ]
        }, status: :unprocessable_entity
      end

      private

      def password_params
        params.require(:current_password)
        raise ActionController::ParameterMissing.new(:password) unless params.key?(:password)
        raise ActionController::ParameterMissing.new(:password_confirmation) unless params.key?(:password_confirmation)
        params.permit(:current_password, :password, :password_confirmation)
      end
    end
  end
end
