require 'rails_helper'

RSpec.describe ScrapeLog, type: :model do
  describe "validations" do
    subject { build(:scrape_log) }

    it { should validate_presence_of(:date) }
    it { should validate_uniqueness_of(:facility).scoped_to(:date) }
  end

  describe "enums" do
    it do
      should define_enum_for(:status)
        .with_values(completed: "completed", failed: "failed")
        .backed_by_column_of_type(:string)
    end
  end
end
