require "rails_helper"

RSpec.describe "Auth", type: :request do
  include_context "with OpenAPI contract"
  describe "POST /api/v1/auth" do
    it "returns a token for valid credentials" do
      user = create(:user, email: "member@example.com", password: "Password123!")

      post "/api/v1/auth", params: { email: user.email, password: "Password123!" }, as: :json

      expect(response).to have_http_status(:ok)
      expect(response.parsed_body).to include("token")

      raw_token = response.parsed_body["token"]
      token = Token.find_by(digest: Token.digest(raw_token))

      expect(token).to be_present
      expect(token.user).to eq(user)
    end

    it "returns unauthorized for an invalid email" do
      create(:user, email: "member@example.com", password: "Password123!")

      post "/api/v1/auth", params: { email: "missing@example.com", password: "Password123!" }, as: :json

      expect(response).to have_http_status(:unauthorized)
      expect(response.parsed_body).to eq("errors" => [ { "status" => 401, "title" => "Unauthorized", "detail" => "Invalid email or password" } ])
    end

    it "returns unauthorized for an invalid password" do
      user = create(:user, email: "member@example.com", password: "Password123!")

      post "/api/v1/auth", params: { email: user.email, password: "WrongPassword123!" }, as: :json

      expect(response).to have_http_status(:unauthorized)
      expect(response.parsed_body).to eq("errors" => [ { "status" => 401, "title" => "Unauthorized", "detail" => "Invalid email or password" } ])
    end

    it "returns bad request when params are missing" do
      create(:user, email: "member@example.com", password: "Password123!")

      post "/api/v1/auth", params: { email: "member@example.com" }, as: :json

      expect(response).to have_http_status(:bad_request)
    end
  end
end
