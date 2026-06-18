require "rails_helper"

RSpec.describe SettingsController, type: :request do
  let(:user) { create(:user) }

  def sign_in(user)
    post session_url, params: { email_address: user.email_address, password: "password" }
  end

  describe "GET /settings" do
    context "when not authenticated" do
      it "redirects to the sign in page" do
        get settings_url
        expect(response).to redirect_to(new_session_url)
      end
    end

    context "when authenticated" do
      before { sign_in(user) }

      it "returns http success" do
        get settings_url
        expect(response).to have_http_status(:success)
      end

      it "renders the scan button" do
        get settings_url
        expect(response.body).to include(I18n.t!("settings.show.scrape_button"))
      end
    end
  end

  describe "POST /settings/scrape_locations" do
    context "when not authenticated" do
      it "redirects to the sign in page" do
        post scrape_locations_settings_url
        expect(response).to redirect_to(new_session_url)
      end
    end

    context "when authenticated" do
      before { sign_in(user) }

      it "enqueues a ScrapeLocationsJob" do
        expect { post scrape_locations_settings_url }
          .to have_enqueued_job(GymGhost::Scraper::ScrapeLocationsJob)
      end

      it "redirects to settings with a notice" do
        post scrape_locations_settings_url
        expect(response).to redirect_to(settings_url)
        expect(flash[:notice]).to eq(I18n.t!("flash.locations_scraping_started"))
      end
    end
  end
end
