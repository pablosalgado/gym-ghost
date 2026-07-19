# frozen_string_literal: true

module Api
  module V1
    # Triggers authentication against the downstream gym partner API for a
    # local GymMember and persists the returned tokens as a PartnerToken.
    class PartnerAuthController < ApplicationController
      def create
        gym_member = GymMember.find_by!("LOWER(email) = ?", params.require(:email).to_s.downcase)
        service = Partner::AuthService.new(gym_member:, password: params.require(:password))
        token = service.login

        render json: {
          gym_member_id: gym_member.id,
          token_expires_at: token.token_expires_at.utc.iso8601
        }, status: :created
      end
    end
  end
end
