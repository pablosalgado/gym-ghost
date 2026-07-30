module Api
  module V1
    class PasswordsController < ApplicationController
      def update
        pw_params = password_params

        unless pw_params.key?(:current_password) && pw_params.key?(:password) && pw_params.key?(:password_confirmation)
          render json: {
            errors: [ { status: 422, title: "Validation Failed", detail: "Current password, password, and password confirmation are required" } ]
          }, status: :unprocessable_entity
          return
        end

        if pw_params[:password].blank? || pw_params[:password_confirmation].blank?
          render json: {
            errors: [ { status: 422, title: "Validation Failed", detail: "Password can't be blank" } ]
          }, status: :unprocessable_entity
          return
        end

        unless current_user.authenticate(pw_params[:current_password])
          render json: {
            errors: [ { status: 401, title: "Unauthorized", detail: "Current password is incorrect" } ]
          }, status: :unauthorized
          return
        end

        current_user.update!(pw_params.except(:current_password))
        head :ok
      end

      private

      def password_params
        params.permit(:current_password, :password, :password_confirmation)
      end
    end
  end
end
