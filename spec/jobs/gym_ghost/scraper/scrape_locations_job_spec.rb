require "rails_helper"

RSpec.describe GymGhost::Scraper::ScrapeLocationsJob, type: :job do
  describe "#perform" do
    subject(:job) { described_class.new }

    let(:url) { "http://example.com" }
    let(:scraper_factory) { class_double(GymGhost::Scraper::ScraperFactory) }
    let(:scraper) { instance_double(GymGhost::Scraper::DefaultScraper) }
    let(:cities) { [ "BOGOTÁ, D.C.", "MEDELLÍN" ] }
    let(:bogota_facilities) { [ "Colina", "Cedro Bolivar" ] }
    let(:medellin_facilities) { [ "Corporate Center" ] }

    before do
      allow(scraper_factory).to receive(:build_scraper)
                                   .with(url, nil, nil)
                                   .and_return(scraper)

      allow(scraper).to receive(:scrape_cities)
                           .and_return(cities)

      allow(scraper).to receive(:scrape_facilities)
                           .with("BOGOTÁ, D.C.")
                           .and_return(bogota_facilities)

      allow(scraper).to receive(:scrape_facilities)
                           .with("MEDELLÍN")
                           .and_return(medellin_facilities)

      allow(scraper).to receive(:end_session)
    end

    it "creates cities from scraped data" do
      expect { job.perform(url, scraper_factory) }
        .to change(City, :count).by(2)
      expect(City.pluck(:name)).to include("BOGOTÁ, D.C.", "MEDELLÍN")
    end

    it "creates facilities for each city" do
      job.perform(url, scraper_factory)
      bogota = City.find_by!(name: "BOGOTÁ, D.C.")
      medellin = City.find_by!(name: "MEDELLÍN")

      expect(bogota.facilities.pluck(:name)).to match_array(bogota_facilities)
      expect(medellin.facilities.pluck(:name)).to match_array(medellin_facilities)
    end

    it "does not duplicate existing cities" do
      create(:city, name: "BOGOTÁ, D.C.")

      expect { job.perform(url, scraper_factory) }
        .to change(City, :count).by(1)
    end

    it "does not duplicate existing facilities" do
      city = create(:city, name: "BOGOTÁ, D.C.")
      create(:facility, name: "Colina", city: city)

      job.perform(url, scraper_factory)

      expect(city.facilities.count).to eq(2)
    end

    it "calls end_session when done" do
      job.perform(url, scraper_factory)
      expect(scraper).to have_received(:end_session)
    end

    it "calls end_session even on error" do
      allow(scraper).to receive(:scrape_cities).and_raise(StandardError)

      expect { job.perform(url, scraper_factory) }
        .to raise_error(StandardError)
      expect(scraper).to have_received(:end_session)
    end
  end
end
