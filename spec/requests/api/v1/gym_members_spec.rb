require "rails_helper"

RSpec.describe "GymMembers", type: :request do
  include_context "with OpenAPI contract"

  describe "GET /api/v1/gym_members" do
    it "returns unauthorized when header is missing" do
      get "/api/v1/gym_members"

      expect(response).to have_http_status(:unauthorized)
      expect(response.parsed_body).to eq(
        "errors" => [
          {
            "status" => 401,
            "title" => "Unauthorized",
            "detail" => "Authentication token is missing or invalid."
          }
        ]
      )
    end

    it "returns unauthorized when token is invalid" do
      get "/api/v1/gym_members", headers: { "Authorization" => "Bearer invalid-token" }

      expect(response).to have_http_status(:unauthorized)
      expect(response.parsed_body).to eq(
        "errors" => [
          {
            "status" => 401,
            "title" => "Unauthorized",
            "detail" => "Authentication token is missing or invalid."
          }
        ]
      )
    end

    it "returns all gym members ordered by email" do
      user = create(:user)
      raw_token = SecureRandom.hex(32)
      create(:token, user:, digest: Token.digest(raw_token))
      create(:gym_member, email: "beta@example.com")
      create(:gym_member, email: "alpha@example.com")

      get "/api/v1/gym_members", headers: { "Authorization" => "Bearer #{raw_token}" }

      expect(response).to have_http_status(:ok)
      body = response.parsed_body
      expect(body).to have_key("gym_members")
      expect(body["gym_members"].size).to eq(2)
      expect(body["gym_members"].map { |m| m["email"] }).to eq([ "alpha@example.com", "beta@example.com" ])
    end

    it "returns only id and email fields" do
      user = create(:user)
      raw_token = SecureRandom.hex(32)
      create(:token, user:, digest: Token.digest(raw_token))
      create(:gym_member)

      get "/api/v1/gym_members", headers: { "Authorization" => "Bearer #{raw_token}" }

      member = response.parsed_body["gym_members"].first
      expect(member.keys).to match_array(%w[id email])
    end

    it "returns empty array when no gym members exist" do
      user = create(:user)
      raw_token = SecureRandom.hex(32)
      create(:token, user:, digest: Token.digest(raw_token))

      get "/api/v1/gym_members", headers: { "Authorization" => "Bearer #{raw_token}" }

      expect(response).to have_http_status(:ok)
      expect(response.parsed_body["gym_members"]).to eq([])
    end
  end

  describe "POST /api/v1/gym_members" do
    it "returns unauthorized when header is missing" do
      post "/api/v1/gym_members", params: { email: "new@example.com", password: "Password123!" }, as: :json

      expect(response).to have_http_status(:unauthorized)
    end

    it "creates a gym member with email and password" do
      user = create(:user)
      raw_token = SecureRandom.hex(32)
      create(:token, user:, digest: Token.digest(raw_token))

      post "/api/v1/gym_members",
           params: { email: "new@example.com", password: "Password123!" },
           headers: { "Authorization" => "Bearer #{raw_token}" },
           as: :json

      expect(response).to have_http_status(:created)
      body = response.parsed_body
      expect(body).to have_key("gym_member")
      expect(body["gym_member"]["id"]).to be_present
      expect(body["gym_member"]["email"]).to eq("new@example.com")
      expect(body["gym_member"].keys).to match_array(%w[id email])
    end

    it "returns 422 for a duplicate email (case-insensitive)" do
      user = create(:user)
      raw_token = SecureRandom.hex(32)
      create(:token, user:, digest: Token.digest(raw_token))
      create(:gym_member, email: "existing@example.com")

      post "/api/v1/gym_members",
           params: { email: "EXISTING@example.com", password: "Password123!" },
           headers: { "Authorization" => "Bearer #{raw_token}" },
           as: :json

      expect(response).to have_http_status(:unprocessable_entity)
      body = response.parsed_body
      expect(body).to have_key("errors")
      expect(body["errors"].first["status"]).to eq(422)
    end

    it "returns 422 for empty password" do
      user = create(:user)
      raw_token = SecureRandom.hex(32)
      create(:token, user:, digest: Token.digest(raw_token))

      post "/api/v1/gym_members",
           params: { email: "new@example.com", password: "" },
           headers: { "Authorization" => "Bearer #{raw_token}" },
           as: :json

      expect(response).to have_http_status(:unprocessable_entity)
    end

    it "returns 400 for missing required fields" do
      user = create(:user)
      raw_token = SecureRandom.hex(32)
      create(:token, user:, digest: Token.digest(raw_token))

      post "/api/v1/gym_members",
           params: { password: "Password123!" },
           headers: { "Authorization" => "Bearer #{raw_token}" },
           as: :json

      expect(response).to have_http_status(:bad_request)
    end
  end

  describe "PATCH /api/v1/gym_members/:id" do
    it "returns unauthorized when header is missing" do
      member = create(:gym_member)

      patch "/api/v1/gym_members/#{member.id}", params: { email: "updated@example.com" }, as: :json

      expect(response).to have_http_status(:unauthorized)
    end

    it "updates the email" do
      user = create(:user)
      raw_token = SecureRandom.hex(32)
      create(:token, user:, digest: Token.digest(raw_token))
      member = create(:gym_member, email: "original@example.com")

      patch "/api/v1/gym_members/#{member.id}",
            params: { email: "updated@example.com" },
            headers: { "Authorization" => "Bearer #{raw_token}" },
            as: :json

      expect(response).to have_http_status(:ok)
      body = response.parsed_body
      expect(body["gym_member"]["email"]).to eq("updated@example.com")
      expect(member.reload.email).to eq("updated@example.com")
    end

    it "updates the password" do
      user = create(:user)
      raw_token = SecureRandom.hex(32)
      create(:token, user:, digest: Token.digest(raw_token))
      member = create(:gym_member, password: "OldPassword123!")

      patch "/api/v1/gym_members/#{member.id}",
            params: { password: "NewPassword456!" },
            headers: { "Authorization" => "Bearer #{raw_token}" },
            as: :json

      expect(response).to have_http_status(:ok)
      expect(member.reload.password).to eq("NewPassword456!")
    end

    it "does not clear the password when password param is omitted" do
      user = create(:user)
      raw_token = SecureRandom.hex(32)
      create(:token, user:, digest: Token.digest(raw_token))
      member = create(:gym_member, password: "OriginalPassword123!")

      patch "/api/v1/gym_members/#{member.id}",
            params: { email: "updated@example.com" },
            headers: { "Authorization" => "Bearer #{raw_token}" },
            as: :json

      expect(response).to have_http_status(:ok)
      expect(member.reload.password).to eq("OriginalPassword123!")
    end

    it "does not clear the password when password param is blank" do
      user = create(:user)
      raw_token = SecureRandom.hex(32)
      create(:token, user:, digest: Token.digest(raw_token))
      member = create(:gym_member, password: "OriginalPassword123!")

      patch "/api/v1/gym_members/#{member.id}",
            params: { password: "" },
            headers: { "Authorization" => "Bearer #{raw_token}" },
            as: :json

      expect(response).to have_http_status(:ok)
      expect(member.reload.password).to eq("OriginalPassword123!")
    end

    it "returns 422 for duplicate email" do
      user = create(:user)
      raw_token = SecureRandom.hex(32)
      create(:token, user:, digest: Token.digest(raw_token))
      create(:gym_member, email: "taken@example.com")
      member = create(:gym_member, email: "original@example.com")

      patch "/api/v1/gym_members/#{member.id}",
            params: { email: "taken@example.com" },
            headers: { "Authorization" => "Bearer #{raw_token}" },
            as: :json

      expect(response).to have_http_status(:unprocessable_entity)
      body = response.parsed_body
      expect(body).to have_key("errors")
      expect(body["errors"].first["status"]).to eq(422)
    end

    it "returns 404 for non-existent member" do
      user = create(:user)
      raw_token = SecureRandom.hex(32)
      create(:token, user:, digest: Token.digest(raw_token))

      patch "/api/v1/gym_members/999999",
            params: { email: "updated@example.com" },
            headers: { "Authorization" => "Bearer #{raw_token}" },
            as: :json

      expect(response).to have_http_status(:not_found)
    end
  end
end
