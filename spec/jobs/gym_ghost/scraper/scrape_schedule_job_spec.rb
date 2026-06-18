require "rails_helper"
require "fugit"

RSpec.describe GymGhost::Scraper::ScrapeScheduleJob, type: :job do
  describe "recurring schedule" do
    subject(:schedule_expression) do
      config = YAML.safe_load_file(Rails.root.join("config/recurring.yml"))
      config.dig("production", "scrape_gym_schedule", "schedule")
    end

    it "is defined in config/recurring.yml" do
      expect(schedule_expression).to be_present
    end

    it "is a valid schedule expression" do
      expect(Fugit.parse(schedule_expression)).not_to be_nil
    end

    it "fires every Sunday at midnight" do
      cron = Fugit.parse(schedule_expression)

      # Collect the next 4 fire times starting from an arbitrary reference point.
      next_times = []
      t = Time.utc(2026, 4, 22) # a known Wednesday – neutral starting point
      4.times do
        t = cron.next_time(t).utc
        next_times << t
      end

      aggregate_failures do
        next_times.each do |time|
          expect(time.wday).to eq(0), "expected Sunday (wday 0), got wday #{time.wday} for #{time}"
          expect(time.hour).to eq(5), "expected hour 5, got #{time.hour} for #{time}"
          expect(time.min).to eq(0), "expected minute 0, got #{time.min} for #{time}"
        end
      end
    end
  end

  describe "#perform" do
    subject(:job) { described_class.new }

    context "when scraping fails" do
      context "when database transaction fails" do
        let(:date) { Date.current }
        let(:facility_name) { "Colina" }
        let(:url) { "http://example.com" }
        let(:scraper_factory) { class_double(GymGhost::Scraper::ScraperFactory) }
        let(:scraper) { instance_double(GymGhost::Scraper::DefaultScraper) }
        let(:cities) { [ "BOGOTÁ, D.C." ] }
        let(:facilities) { [ facility_name ] }

        before do
          allow(scraper_factory).to receive(:build_scraper)
                                       .with(url, nil, nil)
                                       .and_return(scraper)

          allow(scraper).to receive(:scrape_cities)
                               .and_return(cities)

          allow(scraper).to receive(:scrape_facilities)
                               .and_return(facilities)

          # This makes the request to fail because schedule is invalid and it can't scrape anything
          allow(scraper).to receive(:scrape_schedule)
                              .and_return([ {} ])

          allow(scraper).to receive(:end_session)
        end

        it "rolls back" do
          expect { job.perform(date, facility_name, url, scraper_factory) }
            .to raise_error(ActiveRecord::RecordInvalid)
          expect(scraper).to have_received(:end_session)
        end
      end

      context "when driver timeouts" do
        it "handles the error gracefully" do
          skip "This test would require simulating a driver timeout, which can be done by stubbing the scraper's methods to raise a timeout error. The job should rescue this error and log it without crashing, ensuring that the scraping process can be retried later without issues."
        end
      end
    end
  end
end
