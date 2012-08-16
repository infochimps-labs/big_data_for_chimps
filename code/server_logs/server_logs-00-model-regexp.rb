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
    \s(HTTP/[\d\.]+)|-)\"      # protocol       HTTP/1.1"
             \s(\d+)           # response_code  200
             \s(\d+|-)         # size           569
           \s\"([^\"]*)\"      # referer        "http://infochimps.org/search?query=CAC"
           \s\"([^\"]*)\"      # ua             "Mozilla/5.0 (Windows; U; Windows NT 5.1; fr; rv:1.9.0.16) Gecko/2009120208 Firefox/3.0.16"
          \z}x)
end
