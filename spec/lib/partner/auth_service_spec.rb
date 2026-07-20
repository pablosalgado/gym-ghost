require "rails_helper"

RSpec.describe Partner::AuthService do
  def build_jwt(exp: 1.hour.from_now.to_i)
    header  = Base64.urlsafe_encode64('{"alg":"HS256","typ":"JWT"}', padding: false)
    payload = Base64.urlsafe_encode64({ exp: }.to_json, padding: false)
    sig     = Base64.urlsafe_encode64("fake-sig", padding: false)
    "#{header}.#{payload}.#{sig}"
  end

  around do |example|
    old_url          = ENV.delete("PARTNER_API_BASE_URL")
    old_partner_name = ENV.delete("TEST_PARTNER_AUTH_PARTNER_NAME")
    old_branch_id    = ENV.delete("TEST_PARTNER_AUTH_BRANCH_ID")
    old_branch_name  = ENV.delete("TEST_PARTNER_AUTH_BRANCH_NAME")
    old_token_branch = ENV.delete("TEST_PARTNER_AUTH_TOKEN_BRANCH")
    old_country_code = ENV.delete("TEST_PARTNER_AUTH_COUNTRY_CODE")
    old_referer      = ENV.delete("PARTNER_AUTH_REFERER")
    old_origin       = ENV.delete("PARTNER_AUTH_ORIGIN")
    ENV["PARTNER_API_BASE_URL"]             = "http://partner.test"
    ENV["TEST_PARTNER_AUTH_PARTNER_NAME"]   = "TestPartner"
    ENV["TEST_PARTNER_AUTH_BRANCH_ID"]      = "6"
    ENV["TEST_PARTNER_AUTH_BRANCH_NAME"]    = "Test Branch"
    ENV["TEST_PARTNER_AUTH_TOKEN_BRANCH"]   = "TOKEN001"
    ENV["TEST_PARTNER_AUTH_COUNTRY_CODE"]   = "CO"
    ENV["PARTNER_AUTH_REFERER"]        = "https://partner.test"
    ENV["PARTNER_AUTH_ORIGIN"]         = "https://partner.test"
    example.run
  ensure
    ENV["PARTNER_API_BASE_URL"]           = old_url
    ENV["TEST_PARTNER_AUTH_PARTNER_NAME"] = old_partner_name
    ENV["TEST_PARTNER_AUTH_BRANCH_ID"]    = old_branch_id
    ENV["TEST_PARTNER_AUTH_BRANCH_NAME"]  = old_branch_name
    ENV["TEST_PARTNER_AUTH_TOKEN_BRANCH"] = old_token_branch
    ENV["TEST_PARTNER_AUTH_COUNTRY_CODE"] = old_country_code
    ENV["PARTNER_AUTH_REFERER"]      = old_referer
    ENV["PARTNER_AUTH_ORIGIN"]       = old_origin
  end

  let(:gym_member) { create(:gym_member, email: "alice@example.com", password: "Password123!") }

  subject(:service) { described_class.new(gym_member:) }

  describe "#login" do
    context "when the partner API returns a successful response" do
      let(:exp_epoch) { 2.hours.from_now.to_i }
      let(:jwt)       { build_jwt(exp: exp_epoch) }

      before do
        success_response = instance_double(HTTParty::Response,
                                           success?: true,
                                           code: 200,
                                           parsed_response: {
                                             "status" => "OK",
                                             "data" => {
                                               "access_token"  => jwt,
                                               "refresh_token" => "refresh_abc123"
                                             },
                                             "errors" => []
                                           })
        allow(described_class).to receive(:post).and_return(success_response)
      end

      it "creates a PartnerToken with decoded expiry" do
        token = service.login

        expect(token).to be_persisted
        expect(token.access_token).to eq(jwt)
        expect(token.refresh_token).to eq("refresh_abc123")
        expect(token.token_expires_at).to eq(Time.at(exp_epoch).utc)
        expect(token.gym_member).to eq(gym_member)
      end

      it "returns the persisted PartnerToken" do
        expect(service.login).to be_a(PartnerToken)
      end
    end

    context "when the partner API returns a non-success status" do
      before do
        fail_response = instance_double(HTTParty::Response,
                                        success?: false,
                                        code: 401,
                                        parsed_response: { "error" => "Invalid credentials" })
        allow(described_class).to receive(:post).and_return(fail_response)
      end

      it "raises Partner::AuthenticationError" do
        expect { service.login }.to raise_error(Partner::AuthenticationError, /Invalid credentials/)
      end
    end

    context "when the response is missing access_token" do
      before do
        incomplete_response = instance_double(HTTParty::Response,
                                              success?: true,
                                              code: 200,
                                              parsed_response: {
                                                "status" => "OK",
                                                "data" => { "refresh_token" => "refresh_only" },
                                                "errors" => []
                                              })
        allow(described_class).to receive(:post).and_return(incomplete_response)
      end

      it "raises Partner::AuthenticationError" do
        expect { service.login }
          .to raise_error(Partner::AuthenticationError, "Missing access token in partner response")
      end
    end

    context "when the response is missing refresh_token" do
      before do
        incomplete_response = instance_double(HTTParty::Response,
                                              success?: true,
                                              code: 200,
                                              parsed_response: {
                                                "status" => "OK",
                                                "data" => { "access_token" => build_jwt },
                                                "errors" => []
                                              })
        allow(described_class).to receive(:post).and_return(incomplete_response)
      end

      it "raises Partner::AuthenticationError" do
        expect { service.login }
          .to raise_error(Partner::AuthenticationError, "Missing refresh token in partner response")
      end
    end

    context "when the access_token JWT has no exp claim" do
      before do
        header       = Base64.urlsafe_encode64('{"alg":"HS256","typ":"JWT"}', padding: false)
        payload      = Base64.urlsafe_encode64('{"iat":1234}', padding: false)
        sig          = Base64.urlsafe_encode64("fake", padding: false)
        jwt          = "#{header}.#{payload}.#{sig}"
        bad_response = instance_double(HTTParty::Response,
                                        success?: true,
                                        code: 200,
                                        parsed_response: {
                                          "status" => "OK",
                                          "data" => {
                                            "access_token"  => jwt,
                                            "refresh_token" => "refresh_abc"
                                          },
                                          "errors" => []
                                        })
        allow(described_class).to receive(:post).and_return(bad_response)
      end

      it "raises Partner::AuthenticationError" do
        expect { service.login }
          .to raise_error(Partner::AuthenticationError, "JWT missing exp claim")
      end
    end

    context "when the gym member has a stored partner password" do
      let(:exp_epoch) { 2.hours.from_now.to_i }
      let(:jwt)       { build_jwt(exp: exp_epoch) }

      before do
        success_response = instance_double(HTTParty::Response,
                                            success?: true,
                                            code: 200,
                                            parsed_response: {
                                              "status" => "OK",
                                              "data" => {
                                                "access_token"  => jwt,
                                                "refresh_token" => "refresh_abc123"
                                              },
                                              "errors" => []
                                            })
        allow(described_class).to receive(:post).and_return(success_response)
      end

      it "sends the decrypted stored password in the login body" do
        service.login

        expect(described_class).to have_received(:post).with(
          anything,
          hash_including(body: /"password":"Password123!"/)
        )
      end
    end

    context "when the gym member has a blank stored password" do
      let(:gym_member) { create(:gym_member, email: "alice@example.com", password: "Password123!") }

      before { allow(gym_member).to receive(:password).and_return("") }

      it "raises Partner::AuthenticationError before calling the partner API" do
        expect(described_class).not_to receive(:post)

        expect { service.login }
          .to raise_error(Partner::AuthenticationError, "Missing partner password")
      end
    end
  end
end
