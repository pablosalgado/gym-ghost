require "rails_helper"

RSpec.describe "Partner Auth", type: :request do
  describe "POST /api/v1/partner/auth" do
    def build_jwt(exp: 1.hour.from_now.to_i)
      header  = Base64.urlsafe_encode64('{"alg":"HS256","typ":"JWT"}', padding: false)
      payload = Base64.urlsafe_encode64({ exp: }.to_json, padding: false)
      sig     = Base64.urlsafe_encode64("fake-sig", padding: false)
      "#{header}.#{payload}.#{sig}"
    end

    def authenticated_headers
      user = create(:user)
      raw_token = SecureRandom.hex(32)
      create(:token, user:, digest: Token.digest(raw_token))

      { "Authorization" => "Bearer #{raw_token}" }
    end

    it "returns created with token_expires_at for a valid partner login" do
      gym_member = create(:gym_member, email: "alice@example.com", password: "Password123!")
      exp_epoch  = 2.hours.from_now.to_i
      jwt        = build_jwt(exp: exp_epoch)
      success_response = instance_double(HTTParty::Response,
                                         success?: true,
                                         code: 200,
                                         parsed_response: {
                                           "access_token"  => jwt,
                                           "refresh_token" => "refresh_abc123"
                                         })

      allow(Partner::AuthService).to receive(:post).and_return(success_response)

      post "/api/v1/partner/auth",
           params: { email: "alice@example.com", password: "Password123!" },
           headers: authenticated_headers,
           as: :json

      expect(response).to have_http_status(:created)

      body = response.parsed_body
      expect(body["gym_member_id"]).to eq(gym_member.id)
      expect(Time.parse(body["token_expires_at"])).to eq(Time.at(exp_epoch).utc)

      partner_token = gym_member.partner_tokens.last
      expect(partner_token).to be_present
      expect(partner_token.access_token).to eq(jwt)
      expect(partner_token.refresh_token).to eq("refresh_abc123")
      expect(partner_token.token_expires_at).to eq(Time.at(exp_epoch).utc)
    end

    it "returns 401 when partner API returns non-success" do
      create(:gym_member, email: "alice@example.com", password: "Password123!")
      fail_response = instance_double(HTTParty::Response,
                                      success?: false,
                                      code: 401,
                                      parsed_response: { "error" => "Invalid credentials" })

      allow(Partner::AuthService).to receive(:post).and_return(fail_response)

      post "/api/v1/partner/auth",
           params: { email: "alice@example.com", password: "Password123!" },
           headers: authenticated_headers,
           as: :json

      expect(response).to have_http_status(:unauthorized)

      body = response.parsed_body
      expect(body["errors"].first["detail"]).to eq("Invalid credentials")
    end

    it "returns 404 when the GymMember does not exist" do
      post "/api/v1/partner/auth",
           params: { email: "missing@example.com", password: "Password123!" },
           headers: authenticated_headers,
           as: :json

      expect(response).to have_http_status(:not_found)
    end

    it "returns 401 when unauthenticated" do
      create(:gym_member, email: "alice@example.com", password: "Password123!")

      post "/api/v1/partner/auth",
           params: { email: "alice@example.com", password: "Password123!" },
           as: :json

      expect(response).to have_http_status(:unauthorized)
    end

    it "returns 401 when partner response is missing access_token" do
      create(:gym_member, email: "alice@example.com", password: "Password123!")
      incomplete_response = instance_double(HTTParty::Response,
                                            success?: true,
                                            code: 200,
                                            parsed_response: { "refresh_token" => "refresh_only" })

      allow(Partner::AuthService).to receive(:post).and_return(incomplete_response)

      post "/api/v1/partner/auth",
           params: { email: "alice@example.com", password: "Password123!" },
           headers: authenticated_headers,
           as: :json

      expect(response).to have_http_status(:unauthorized)
      expect(response.parsed_body["errors"].first["detail"]).to eq("Missing access token in partner response")
    end

    it "returns 401 when the access_token JWT has no exp claim" do
      create(:gym_member, email: "alice@example.com", password: "Password123!")
      header  = Base64.urlsafe_encode64('{"alg":"HS256","typ":"JWT"}', padding: false)
      payload = Base64.urlsafe_encode64('{"iat":1234}', padding: false) # no exp
      sig     = Base64.urlsafe_encode64("fake", padding: false)
      jwt     = "#{header}.#{payload}.#{sig}"

      incomplete_response = instance_double(HTTParty::Response,
                                            success?: true,
                                            code: 200,
                                            parsed_response: {
                                              "access_token"  => jwt,
                                              "refresh_token" => "refresh_abc"
                                            })

      allow(Partner::AuthService).to receive(:post).and_return(incomplete_response)

      post "/api/v1/partner/auth",
           params: { email: "alice@example.com", password: "Password123!" },
           headers: authenticated_headers,
           as: :json

      expect(response).to have_http_status(:unauthorized)
      expect(response.parsed_body["errors"].first["detail"]).to eq("JWT missing exp claim")
    end
  end
end
