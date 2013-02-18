class Logline
  class_attribute :raw_regex

  #
  # Regular expression to parse an apache log line.
  #
  # 83.240.154.3 - - [07/Jun/2008:20:37:11 +0000] "GET /faq HTTP/1.1" 200 569 "http://infochimps.org/search?query=your_mom" "Mozilla/5.0 (Windows; U; Windows NT 5.1; fr; rv:1.9.0.16) Gecko/2009120208 Firefox/3.0.16"
  #
  self.raw_regex = Regexp.compile(%r{\A
               (?<ip_address>   \S+)               # ip_address     83.240.154.3
             \s(?<rfc_1413>     \S+)               # rfc_1413       -
             \s(?<userid>       \S+)               # userid         -
                                                   #
           \s\[(?<requested_at>                    #
                                \d+/\w+/\d+        # date part      [07/Jun/2008
                               :\d+:\d+:\d+        # time part      :20:37:11
                              \s[\+\-]\S*)\]       # timezone       +0000]
                                                   #
        \s\"(?:(?<http_method>  \S+)               # http_method    "GET
             \s(?<path>         \S+)               # path           /faq
             \s(?<protocol>     HTTP/[\d\.]+)|-)\" # protocol       HTTP/1.1"
                                                   #
             \s(?<response_code>\d+)               # response_code  200
             \s(?<bytesize>     \d+|-)             # bytesize       569
           \s\"(?<referer>      [^\"]*)\"          # referer        "http://infochimps.org/search?query=CAC"
           \s\"(?<user_agent>   [^\"]*)\"          # user_agent     "Mozilla/5.0 (Windows; U; Windows NT 5.1; fr; rv:1.9.0.16) Gecko/2009120208 Firefox/3.0.16"
          \z}x)
end
