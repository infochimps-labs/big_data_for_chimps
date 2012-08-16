class Logline

  MONTHS = { 'Jan' => 1, 'Feb' => 2, 'Mar' => 3, 'Apr' => 4, 'May' => 5, 'Jun' => 6, 'Jul' => 7, 'Aug' => 8, 'Sep' => 9, 'Oct' => 10, 'Nov' => 11, 'Dec' => 12, }

  def receive_visit_time(val)
    if %r{(\d+)/(\w+)/(\d+):(\d+):(\d+):(\d+)\s([\+\-]\d\d)(\d\d)} === val
      day, mo, yr, hour, min, sec, tz1, tz2 = [$1, $2, $3, $4, $5, $6, $7, $8]
      val = Time.new(yr.to_i, MONTHS[mo], day.to_i,
        hour.to_i, min.to_i, sec.to_i, "#{tz1}:#{tz2}")
    end
    super(val)
  end
end
