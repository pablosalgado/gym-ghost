module SchedulesHelper
  def class_type_style(name)
    hue = (name.hash.abs * 137.508) % 360
    {
      card: "hsl(#{hue}, 55%, 50%)",
      card_bg: "hsl(#{hue}, 50%, 96%)"
    }
  end
end
