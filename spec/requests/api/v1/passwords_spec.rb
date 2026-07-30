require "rails_helper"

RSpec.describe "Passwords", type: :request do
  describe "PATCH /api/v1/profile/password" do
    let(:user) { create(:user, email: "member@example.com", password: "Password123!") }
    let(:raw_token) do
      token = SecureRandom.hex(32)
      create(:token, user: user, digest: Token.digest(token))
      token
    end
    let(:auth_headers) { { "Authorization" => "Bearer #{raw_token}" } }

    it "returns 200 OK and updates the password when current password is correct and new password is valid" do
      patch "/api/v1/profile/password",
        params: { current_password: "Password123!", password: "NewPassword123!", password_confirmation: "NewPassword123!" },
        headers: auth_headers,
        as: :json

      expect(response).to have_http_status(:ok)
      expect(response.body).to be_empty

      # Verify password was updated
      user.reload
      expect(user.authenticate("NewPassword123!")).to eq(user)
      expect(user.authenticate("Password123!")).to be_falsey
    end

    it "returns 401 Unauthorized when current password is incorrect" do
      patch "/api/v1/profile/password",
        params: { current_password: "WrongPassword!", password: "NewPassword123!", password_confirmation: "NewPassword123!" },
        headers: auth_headers,
        as: :json

      expect(response).to have_http_status(:unauthorized)
      expect(response.parsed_body).to eq(
        "errors" => [ { "status" => 401, "title" => "Unauthorized", "detail" => "Current password is incorrect" } ]
      )
    end

    it "returns 401 Unauthorized when authentication token is missing" do
      patch "/api/v1/profile/password",
        params: { current_password: "Password123!", password: "NewPassword123!", password_confirmation: "NewPassword123!" },
        as: :json

      expect(response).to have_http_status(:unauthorized)
      expect(response.parsed_body).to eq(
        "errors" => [ { "status" => 401, "title" => "Unauthorized", "detail" => "Authentication token is missing or invalid." } ]
      )
    end

    it "returns 422 Unprocessable Entity when new password and confirmation do not match" do
      patch "/api/v1/profile/password",
        params: { current_password: "Password123!", password: "NewPassword123!", password_confirmation: "Mismatch123!" },
        headers: auth_headers,
        as: :json

      expect(response).to have_http_status(:unprocessable_entity)
      expect(response.parsed_body).to eq(
        "errors" => [ { "status" => 422, "title" => "Validation Failed", "detail" => "Password confirmation doesn't match Password" } ]
      )
    end

    it "returns 422 Unprocessable Entity when new password is blank" do
      patch "/api/v1/profile/password",
        params: { current_password: "Password123!", password: "", password_confirmation: "" },
        headers: auth_headers,
        as: :json

      expect(response).to have_http_status(:unprocessable_entity)
      expect(response.parsed_body["errors"].first["detail"]).to include("Password can't be blank")
    end
  end
end
