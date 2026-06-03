require "rails_helper"

RSpec.describe "PWA support", type: :request do
  it "renders the web app manifest" do
    get pwa_manifest_path(format: :json)

    expect(response).to have_http_status(:ok)
    expect(response.media_type).to eq("application/json")

    manifest = JSON.parse(response.body)
    expect(manifest["name"]).to eq("GymGhost")
    expect(manifest["display"]).to eq("standalone")
    expect(manifest["theme_color"]).to eq("#ffffff")
    expect(manifest["icons"]).not_to be_empty
  end

  it "renders the service worker script" do
    get pwa_service_worker_path

    expect(response).to have_http_status(:ok)
    expect(response.media_type).to include("javascript")
    expect(response.body).to include("self.addEventListener")
  end

  it "includes the manifest link in the application layout" do
    get new_session_path

    expect(response).to have_http_status(:ok)
    expect(response.body).to include(%(rel="manifest"))
    expect(response.body).to include(pwa_manifest_path(format: :json))
  end
end
