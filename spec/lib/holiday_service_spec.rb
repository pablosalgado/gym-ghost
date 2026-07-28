# frozen_string_literal: true

require "rails_helper"

RSpec.describe HolidayService do
  before do
    Rails.cache = ActiveSupport::Cache::MemoryStore.new
    Rails.cache.clear
  end

  describe ".holiday?" do
    it "returns true for a known Colombian holiday (New Year's Day)" do
      expect(described_class.holiday?(Date.new(2026, 1, 1))).to be true
    end

    it "returns true for Independence Day in Colombia" do
      expect(described_class.holiday?(Date.new(2026, 7, 20))).to be true
    end

    it "returns false for a non-holiday date" do
      expect(described_class.holiday?(Date.new(2026, 7, 28))).to be false
    end

    it "accepts Time objects with time zone awareness (America/Bogota)" do
      # 2026-01-01 05:00:00 UTC is 2026-01-01 00:00:00 in America/Bogota (Holiday)
      time_utc = Time.utc(2026, 1, 1, 5, 0, 0)
      expect(described_class.holiday?(time_utc, time_zone: "America/Bogota")).to be true

      # 2026-07-28 05:00:00 UTC is 2026-07-28 00:00:00 in America/Bogota (Not holiday)
      time_utc_normal = Time.utc(2026, 7, 28, 5, 0, 0)
      expect(described_class.holiday?(time_utc_normal, time_zone: "America/Bogota")).to be false
    end

    it "accepts String date representation" do
      expect(described_class.holiday?("2026-01-01")).to be true
      expect(described_class.holiday?("2026-07-28")).to be false
    end

    it "caches results using Rails.cache for performance" do
      expect(Holidays).to receive(:on).once.and_call_original
      expect(described_class.holiday?(Date.new(2026, 1, 1))).to be true
      # Second call should hit Rails.cache
      expect(described_class.holiday?(Date.new(2026, 1, 1))).to be true
    end
  end

  describe ".holiday_name" do
    it "returns the holiday name for a holiday" do
      expect(described_class.holiday_name(Date.new(2026, 1, 1))).to eq("Año Nuevo")
    end

    it "returns nil for a non-holiday" do
      expect(described_class.holiday_name(Date.new(2026, 7, 28))).to be nil
    end
  end
end
