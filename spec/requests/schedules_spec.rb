require 'rails_helper'

RSpec.describe SchedulesController, type: :request do
  let(:user) { create(:user) }

  def sign_in(user)
    post session_url, params: { email_address: user.email_address, password: "password" }
  end

  describe "GET /schedules" do
    context "when not authenticated" do
      it "redirects to the sign in page" do
        get schedules_url
        expect(response).to redirect_to(new_session_url)
      end
    end

    context "when authenticated" do
      before { sign_in(user) }

      it "returns http success" do
        get schedules_url
        expect(response).to have_http_status(:success)
      end

      it "renders city filter options" do
        get schedules_url
        expect(response.body).to include("NYC", "Boston", "Miami")
      end

      it "renders facility filter options" do
        get schedules_url
        expect(response.body).to include("Main Gym", "Pool", "Downtown Studio", "Beach Club")
      end

      it "renders activity filter options" do
        get schedules_url
        expect(response.body).to include("Boxing", "CrossFit", "Pilates", "Swimming", "Yoga")
      end

      it "embeds session data for the Stimulus controller" do
        get schedules_url
        expect(response.body).to include("data-schedule-sessions-value")
      end
    end
  end

  describe "GET /" do
    context "when authenticated" do
      before { sign_in(user) }

      it "returns http success" do
        get root_url
        expect(response).to have_http_status(:success)
      end

      it "renders the schedule week strip" do
        get root_url
        expect(response.body).to include("data-schedule-target=\"weekStrip\"")
      end
    end
  end
end
