require "rails_helper"

RSpec.describe Partner::FacilitiesService do
  around do |example|
    old_url = ENV.delete("PARTNER_BRANCHES_API_BASE_URL")
    ENV["PARTNER_BRANCHES_API_BASE_URL"] = "http://partner.test"
    ENV["PARTNER_BRANCHES_BRAND"] = "TestBrand"
    ENV["PARTNER_AUTH_TOKEN"] = "test_token"
    example.run
  ensure
    ENV["PARTNER_BRANCHES_API_BASE_URL"] = old_url
  end

  subject(:service) { described_class.new }

  describe "#sync" do
    context "with successful response upserts City and Facility" do
      before do
        response = instance_double(HTTParty::Response,
                                   success?: true,
                                   code: 200,
                                   parsed_response: {
                                     "result" => [
                                       {
                                         "id" => 101,
                                         "name" => "",
                                         "evo_token" => "tok",
                                         "display_name" => "7 De Agosto",
                                         "city_name" => "BOGOTÁ, D.C."
                                       }
                                     ],
                                     "errors" => []
                                   })
        allow(described_class).to receive(:get).and_return(response)
      end

      it "creates City and Facility records" do
        facilities = service.sync

        expect(City.count).to eq(1)
        expect(City.first.city_name).to eq("BOGOTÁ, D.C.")

        expect(Facility.count).to eq(1)
        facility = Facility.first
        expect(facility.external_id).to eq(101)
        expect(facility.name).to eq("")
        expect(facility.evo_token).to eq("tok")
        expect(facility.display_name).to eq("7 De Agosto")
        expect(facility.city).to eq(City.first)

        expect(facilities).to be_an(Array)
        expect(facilities.length).to eq(1)
        expect(facilities.first).to eq(facility)
      end
    end

    context "is idempotent — re-running does not duplicate rows" do
      before do
        response = instance_double(HTTParty::Response,
                                   success?: true,
                                   code: 200,
                                   parsed_response: {
                                     "result" => [
                                       {
                                         "id" => 101,
                                         "name" => "Original",
                                         "evo_token" => "tok",
                                         "display_name" => "7 De Agosto",
                                         "city_name" => "BOGOTÁ, D.C."
                                       }
                                     ],
                                     "errors" => []
                                   })
        allow(described_class).to receive(:get).and_return(response)
      end

      it "does not duplicate rows on second run" do
        service.sync

        updated_response = instance_double(HTTParty::Response,
                                           success?: true,
                                           code: 200,
                                           parsed_response: {
                                             "result" => [
                                               {
                                                 "id" => 101,
                                                 "name" => "Updated",
                                                 "evo_token" => "tok2",
                                                 "display_name" => "Updated Name",
                                                 "city_name" => "BOGOTÁ, D.C."
                                               }
                                             ],
                                             "errors" => []
                                           })
        allow(described_class).to receive(:get).and_return(updated_response)

        service.sync

        expect(City.count).to eq(1)
        expect(Facility.count).to eq(1)

        facility = Facility.first
        expect(facility.name).to eq("Updated")
        expect(facility.evo_token).to eq("tok2")
        expect(facility.display_name).to eq("Updated Name")
      end
    end

    context "skips rows with blank city_name" do
      before do
        response = instance_double(HTTParty::Response,
                                   success?: true,
                                   code: 200,
                                   parsed_response: {
                                     "result" => [
                                       { "id" => 1, "city_name" => "", "name" => "X" },
                                       {
                                         "id" => 2,
                                         "city_name" => "Bogota",
                                         "display_name" => "Y",
                                         "name" => "",
                                         "evo_token" => ""
                                       }
                                     ],
                                     "errors" => []
                                   })
        allow(described_class).to receive(:get).and_return(response)
      end

      it "only upserts the valid row" do
        facilities = service.sync

        expect(facilities.length).to eq(1)
        expect(Facility.count).to eq(1)
        expect(City.count).to eq(1)
      end
    end

    context "skips rows with blank id" do
      before do
        response = instance_double(HTTParty::Response,
                                   success?: true,
                                   code: 200,
                                   parsed_response: {
                                     "result" => [
                                       { "id" => nil, "city_name" => "Bogota", "name" => "X" }
                                     ],
                                     "errors" => []
                                   })
        allow(described_class).to receive(:get).and_return(response)
      end

      it "creates no records" do
        facilities = service.sync

        expect(facilities).to be_empty
        expect(City.count).to eq(0)
        expect(Facility.count).to eq(0)
      end
    end

    context "raises Partner::FacilitiesSyncError on non-2xx response" do
      before do
        response = instance_double(HTTParty::Response,
                                   success?: false,
                                   code: 401,
                                   parsed_response: { "error" => "Unauthorized" })
        allow(described_class).to receive(:get).and_return(response)
      end

      it "raises FacilitiesSyncError with the error message" do
        expect { service.sync }.to raise_error(Partner::FacilitiesSyncError, /Unauthorized/)
      end
    end

    context "raises Partner::FacilitiesSyncError on malformed JSON" do
      before do
        response = instance_double(HTTParty::Response,
                                   success?: true,
                                   code: 200,
                                   parsed_response: "not a json hash")
        allow(described_class).to receive(:get).and_return(response)
      end

      it "raises FacilitiesSyncError" do
        expect { service.sync }.to raise_error(Partner::FacilitiesSyncError, "Malformed partner response")
      end
    end

    context "raises Partner::FacilitiesSyncError when result is missing" do
      before do
        response = instance_double(HTTParty::Response,
                                   success?: true,
                                   code: 200,
                                   parsed_response: { "errors" => [ "x" ] })
        allow(described_class).to receive(:get).and_return(response)
      end

      it "raises FacilitiesSyncError" do
        expect { service.sync }.to raise_error(
          Partner::FacilitiesSyncError,
          "Missing result array in partner response"
        )
      end
    end
  end
end
