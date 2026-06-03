module SchedulesHelper
  ACTIVITY_THEMES = {
    "Boxing" => "boxing",
    "CrossFit" => "crossfit",
    "Pilates" => "pilates",
    "Swimming" => "swimming",
    "Yoga" => "yoga"
  }.freeze

  def activity_theme(activity)
    ACTIVITY_THEMES.fetch(activity.to_s, "default")
  end
end

