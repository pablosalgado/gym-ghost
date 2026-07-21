module Api
  module V1
    class AuthController < ApplicationController
      allow_unauthenticated_access only: :create

      def create
        user = user_for_email(login_params[:email])
        return invalid_credentials unless user&.authenticate(login_params[:password])

        raw_token = SecureRandom.hex(32)
        user.tokens.create!(digest: Token.digest(raw_token))

        render json: { token: raw_token }, status: :ok
      rescue ActionController::ParameterMissing
        invalid_credentials
      end

      private

      def login_params
        {
          email: params.require(:email),
          password: params.require(:password)
        }
      end

      def user_for_email(email)
        User.find_by("LOWER(email) = ?", email.to_s.downcase)
      end

      def invalid_credentials
        render json: {
          errors: [ { status: 401, title: "Unauthorized", detail: "Invalid email or password" } ]
        }, status: :unauthorized
      end
    end
  end
end
