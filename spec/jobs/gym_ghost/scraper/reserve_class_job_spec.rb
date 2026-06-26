require "rails_helper"

RSpec.describe GymGhost::Scraper::ReserveClassJob, type: :job do
  describe "#perform" do
    subject(:job) { described_class.new }

    let(:user) { create(:user) }
    let(:schedule) { create(:schedule, start_time: 2.days.from_now) }
    let(:pc) { create(:programmed_class, schedule: schedule, user: user, status: :programmed) }
    let(:scraper) { instance_double(GymGhost::Scraper::DefaultScraper) }
    let(:scraper_factory) { class_double(GymGhost::Scraper::ScraperFactory) }

    before do
      allow(scraper_factory).to receive(:build_scraper).and_return(scraper)
      allow(scraper).to receive(:reserve_class).and_return(true)
      allow(scraper).to receive(:end_session)
      stub_const("GymGhost::Scraper::ScraperFactory", scraper_factory)
    end

    it "builds a scraper with credentials" do
      job.perform(pc.id)
      expect(scraper_factory).to have_received(:build_scraper)
        .with(Rails.application.credentials.dig(:gym, :url),
              Rails.application.credentials.dig(:gym, :username),
              Rails.application.credentials.dig(:gym, :password))
    end

    it "calls reserve_class with correct params" do
      job.perform(pc.id)
      city = schedule.facility.city.name
      facility = schedule.facility.name
      date = schedule.start_time.to_date
      time = schedule.start_time.strftime("%H:%M")
      expect(scraper).to have_received(:reserve_class).with(city, facility, date, time)
    end

    it "sets status to reserved on success" do
      job.perform(pc.id)
      expect(pc.reload).to be_reserved
    end

    it "sets status to failed on failure" do
      allow(scraper).to receive(:reserve_class).and_return(false)
      job.perform(pc.id)
      expect(pc.reload).to be_failed
    end

    it "ends the scraper session" do
      job.perform(pc.id)
      expect(scraper).to have_received(:end_session)
    end

    context "when the programmed class is no longer programmed" do
      before { pc.update!(status: :canceled) }

      it "does not call reserve_class" do
        job.perform(pc.id)
        expect(scraper).not_to have_received(:reserve_class)
      end
    end
  end
end
