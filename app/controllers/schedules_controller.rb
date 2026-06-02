class SchedulesController < ApplicationController
  MOCK_SESSIONS = [
    { day_offset: 0, time: "07:00", city: "NYC",    facility: "Main Gym",       activity: "Boxing" },
    { day_offset: 0, time: "09:00", city: "NYC",    facility: "Pool",           activity: "Swimming" },
    { day_offset: 0, time: "11:00", city: "Boston", facility: "Downtown Studio", activity: "Yoga" },
    { day_offset: 0, time: "13:00", city: "Miami",  facility: "Beach Club",     activity: "Pilates" },
    { day_offset: 1, time: "08:00", city: "NYC",    facility: "Main Gym",       activity: "CrossFit" },
    { day_offset: 1, time: "10:00", city: "NYC",    facility: "Pool",           activity: "Swimming" },
    { day_offset: 1, time: "12:00", city: "Boston", facility: "Downtown Studio", activity: "Pilates" },
    { day_offset: 1, time: "17:00", city: "Miami",  facility: "Beach Club",     activity: "Yoga" },
    { day_offset: 2, time: "07:30", city: "NYC",    facility: "Main Gym",       activity: "Boxing" },
    { day_offset: 2, time: "09:30", city: "Boston", facility: "Downtown Studio", activity: "CrossFit" },
    { day_offset: 2, time: "11:30", city: "Miami",  facility: "Beach Club",     activity: "Swimming" },
    { day_offset: 2, time: "14:00", city: "NYC",    facility: "Pool",           activity: "Yoga" },
    { day_offset: 3, time: "08:00", city: "NYC",    facility: "Pool",           activity: "Swimming" },
    { day_offset: 3, time: "10:00", city: "NYC",    facility: "Main Gym",       activity: "Yoga" },
    { day_offset: 3, time: "12:00", city: "Boston", facility: "Downtown Studio", activity: "Pilates" },
    { day_offset: 3, time: "15:00", city: "Miami",  facility: "Beach Club",     activity: "Boxing" },
    { day_offset: 4, time: "07:00", city: "NYC",    facility: "Main Gym",       activity: "CrossFit" },
    { day_offset: 4, time: "09:00", city: "Boston", facility: "Downtown Studio", activity: "Yoga" },
    { day_offset: 4, time: "11:00", city: "Miami",  facility: "Beach Club",     activity: "Swimming" },
    { day_offset: 4, time: "16:00", city: "NYC",    facility: "Pool",           activity: "Pilates" },
    { day_offset: 5, time: "09:00", city: "NYC",    facility: "Main Gym",       activity: "Yoga" },
    { day_offset: 5, time: "11:00", city: "NYC",    facility: "Pool",           activity: "Swimming" },
    { day_offset: 5, time: "13:00", city: "Boston", facility: "Downtown Studio", activity: "Boxing" },
    { day_offset: 5, time: "15:00", city: "Miami",  facility: "Beach Club",     activity: "CrossFit" },
    { day_offset: 6, time: "10:00", city: "NYC",    facility: "Main Gym",       activity: "Pilates" },
    { day_offset: 6, time: "12:00", city: "Boston", facility: "Downtown Studio", activity: "Swimming" },
    { day_offset: 6, time: "14:00", city: "Miami",  facility: "Beach Club",     activity: "Yoga" },
    { day_offset: 6, time: "16:00", city: "NYC",    facility: "Pool",           activity: "CrossFit" }
  ].freeze

  CITIES     = MOCK_SESSIONS.map { |s| s[:city] }.uniq.sort.freeze
  FACILITIES = MOCK_SESSIONS.map { |s| s[:facility] }.uniq.sort.freeze
  ACTIVITIES = MOCK_SESSIONS.map { |s| s[:activity] }.uniq.sort.freeze

  def index
    @sessions   = MOCK_SESSIONS
    @cities     = CITIES
    @facilities = FACILITIES
    @activities = ACTIVITIES
  end
end
