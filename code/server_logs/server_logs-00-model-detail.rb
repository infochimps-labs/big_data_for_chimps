class Logline

  #
  # Regular expression to parse an apache log line.
  #
  # 83.240.154.3 - - [07/Jun/2008:20:37:11 +0000] "GET /faq HTTP/1.1" 200 569 "http://infochimps.org/search?query=CAC" "Mozilla/5.0 (Windows; U; Windows NT 5.1; fr; rv:1.9.0.16) Gecko/2009120208 Firefox/3.0.16"
  #
  LOG_RE = Regexp.compile(%r{\A
               (\S+)           # ip             83.240.154.3
             \s(\S+)           # j1             -
             \s(\S+)           # j2             -
           \s\[(\d+/\w+/\d+    # date part      [07/Jun/2008
               :\d+:\d+:\d+    # time part      :20:37:11
             \s[\+\-]\S*)\]    # timezone       +0000]
        \s\"(?:(\S+)           # http_method    "GET
             \s(\S+)           # path           /faq
             \s(\S+)|-)\"      # protocol       HTTP/1.1"
             \s(\d+)           # response_code  200
             \s(\d+|-)         # size           569
           \s\"([^\"]*)\"      # referer        "http://infochimps.org/search?query=CAC"
           \s\"([^\"]*)\"      # ua             "Mozilla/5.0 (Windows; U; Windows NT 5.1; fr; rv:1.9.0.16) Gecko/2009120208 Firefox/3.0.16"
          \z}x)
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
