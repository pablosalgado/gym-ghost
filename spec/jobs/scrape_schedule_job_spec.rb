require 'rails_helper'
require 'fugit'

RSpec.describe ScrapeScheduleJob, type: :job do
  describe 'recurring schedule' do
    subject(:schedule_expression) do
      config = YAML.load_file(Rails.root.join('config/recurring.yml'))
      config.dig('production', 'scrape_gym_schedule', 'schedule')
    end

    it 'is defined in config/recurring.yml' do
      expect(schedule_expression).to be_present
    end

    it 'is a valid schedule expression' do
      expect(Fugit.parse(schedule_expression)).not_to be_nil
    end

    it 'fires every Sunday at midnight' do
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
          expect(time.hour).to eq(0), "expected hour 0, got #{time.hour} for #{time}"
          expect(time.min).to eq(0), "expected minute 0, got #{time.min} for #{time}"
        end
      end
    end
  end
end
