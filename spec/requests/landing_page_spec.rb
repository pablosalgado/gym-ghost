# frozen_string_literal: true

require "rails_helper"

RSpec.describe "Landing Page", type: :request do
  let(:user) { create(:user) }
  let(:city) { create(:city, name: "BOGOTÁ, D.C.") }
  let!(:facility) { create(:facility, name: "Colina", city: city) }
  let!(:schedule) { create(:schedule, facility: facility, class_type: create(:class_type), start_time: Time.current + 1.hour) }

  def sign_in(user)
    post session_url, params: { email_address: user.email_address, password: "password" }
  end

  describe "GET /" do
    context "when authenticated and there are schedules available" do
      before do
        sign_in(user)
      end

      it "returns http success and renders the page" do
        get root_url
        expect(response).to have_http_status(:success)
        expect(response.body).to include("Schedule")
        expect(response.body).to include("Choose day")
        expect(response.body).to include("BOGOTÁ, D.C.")
      end
    end
  end
end
