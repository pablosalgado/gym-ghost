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

      it "renders sessions for the default day (today)" do
        get schedules_url
        expect(response.body).to include("07:00", "09:00")
      end

      it "filters sessions by day param" do
        get schedules_url, params: { day: 1 }
        expect(response.body).to include("08:00")      # day 1 session
        expect(response.body).not_to include("07:00")  # day 0 only session
      end

      it "filters sessions by city param" do
        get schedules_url, params: { day: 0, city: "Boston" }
        expect(response.body).to include("11:00")  # Boston day-0 session time
        expect(response.body).not_to include("07:00")  # NYC-only day-0 session time
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

      it "renders the day navigation strip" do
        get root_url
        expect(response.body).to include("schedules?day=0")
        expect(response.body).to include("schedules?day=6")
      end
    end
  end
end
