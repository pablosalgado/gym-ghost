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
      before do
        sign_in(user)

        @city = create(:city, name: "BOGOTÁ, D.C.")
        @facility = create(:facility, name: "Colina", city: @city)
        @boxing = create(:class_type, name: "Boxing", duration: 60)
        @yoga = create(:class_type, name: "Yoga", duration: 60)

        today_start = Time.current.beginning_of_day
        tomorrow_start = 1.day.from_now.beginning_of_day

        create(:schedule, facility: @facility, class_type: @boxing,
               start_time: today_start + 7.hours, day_of_week: Time.current.wday)
        create(:schedule, facility: @facility, class_type: @yoga,
               start_time: today_start + 9.hours, day_of_week: Time.current.wday)
        create(:schedule, facility: @facility, class_type: @boxing,
               start_time: tomorrow_start + 8.hours, day_of_week: 1.day.from_now.wday)
      end

      it "returns http success" do
        get schedules_url
        expect(response).to have_http_status(:success)
      end

      it "renders city filter options" do
        get schedules_url
        expect(response.body).to include(@city.name)
      end

      it "renders facility filter options" do
        get schedules_url
        expect(response.body).to include(@facility.name)
      end

      it "renders activity filter options" do
        get schedules_url
        expect(response.body).to include(@boxing.name, @yoga.name)
      end

      it "renders sessions for the default day (today)" do
        get schedules_url
        expect(response.body).to include(@boxing.name, @yoga.name)
      end

      it "filters sessions by day param" do
        get schedules_url, params: { day: 1 }
        expect(response.body).to include(@boxing.name)
      end

      it "filters sessions by city param" do
        get schedules_url, params: { day: 0, city: @city.id }
        expect(response.body).to include(@boxing.name)
      end

      it "filters sessions by activity param" do
        get schedules_url, params: { day: 0, activity: @yoga.id }
        expect(response.body).to include(@yoga.name)
        expect(response.body).not_to include("<strong>#{@boxing.name}")
      end

      it "shows all activities when no activity param is given" do
        get schedules_url, params: { day: 0 }
        expect(response.body).to include(@boxing.name, @yoga.name)
      end
    end

    context "when no schedules exist for the day" do
      before do
        sign_in(user)

        @city = create(:city, name: "BOGOTÁ, D.C.")
        @facility = create(:facility, name: "Colina", city: @city)
        create(:class_type, name: "Boxing", duration: 60)

        allow(GymGhost::Scraper::ScrapeScheduleJob).to receive(:perform_now)
      end

      it "triggers a scrape and creates a ScrapeLog" do
        expect { get schedules_url }.to change(ScrapeLog, :count).by(1)
        expect(GymGhost::Scraper::ScrapeScheduleJob).to have_received(:perform_now)
      end

      it "does not scrape again on a second request" do
        get schedules_url
        get schedules_url
        expect(GymGhost::Scraper::ScrapeScheduleJob).to have_received(:perform_now).once
      end
    end
  end

  describe "GET /" do
    context "when authenticated" do
      before do
        sign_in(user)
        city = create(:city, name: "BOGOTÁ, D.C.")
        facility = create(:facility, name: "Colina", city: city)
        class_type = create(:class_type, name: "Boxing", duration: 60)
        create(:schedule, facility: facility, class_type: class_type,
               start_time: Time.current.beginning_of_day + 7.hours, day_of_week: Time.current.wday)
      end

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
