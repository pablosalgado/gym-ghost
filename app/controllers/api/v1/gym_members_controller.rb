module Api
  module V1
    class GymMembersController < ApplicationController
      def index
        members = GymMember.order(:email)
        render json: { gym_members: members.as_json(only: [ :id, :email ]) }
      end

      def create
        member = GymMember.new(member_params)
        member.save!
        render json: { gym_member: member.as_json(only: [ :id, :email ]) }, status: :created
      end

      def update
        member = GymMember.find(params[:id])
        attrs = member_params
        attrs = attrs.except(:password) if attrs[:password].blank?
        member.update!(attrs)
        render json: { gym_member: member.as_json(only: [ :id, :email ]) }
      end

      private

      def member_params
        params.permit(:email, :password)
      end
    end
  end
end
