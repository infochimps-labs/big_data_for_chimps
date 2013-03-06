class Logline
  def day_hr
    [visit_time.year, visit_time.month, visit_time.day, visit_time.hour].join
  end
end
