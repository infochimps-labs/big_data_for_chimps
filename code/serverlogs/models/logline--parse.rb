class Logline

  # Extract structured fields using the `raw_regexp` regular expression
  def self.parse(line)
    mm = raw_regexp.match(line.chomp) or return BadRecord.new('no match', line)
    new(mm.captures_hash)
  end
  ### @export


  class_attribute :raw_regexp

  #
  # Regular expression to parse an apache log line.
  #
  # 83.240.154.3 - - [07/Jun/2008:20:37:11 +0000] "GET /faq?onepage=true HTTP/1.1" 200 569 "http://infochimps.org/search?query=your_mom" "Mozilla/5.0 (Windows; U; Windows NT 5.1; fr; rv:1.9.0.16) Gecko/2009120208 Firefox/3.0.16"
  #
  self.raw_regexp = %r{\A
               (?<ip_address>   \S+)               # ip_address     83.240.154.3
             \ (?<rfc_1413>     \S+)               # rfc_1413       -  (rarely used)
             \ (?<authuser>     \S+)               # authuser       -  (rarely used)
                                                   #
           \ \[(?<requested_at>                    #
                                \d+/\w+/\d+        # date part      [07/Jun/2008
                               :\d+:\d+:\d+        # time part      :20:37:11
                              \ [\+\-]\S*)\]       # timezone       +0000]
                                                   #
        \ \"(?:(?<http_method>  \S+)               # http_method    "GET
             \ (?<uri_str>      \S+)               # uri_str        faq?onepage=true
             \ (?<protocol>     HTTP/[\d\.]+)|-)\" # protocol       HTTP/1.1"
                                                   #
             \ (?<response_code>\d+)               # response_code  200
             \ (?<bytesize>     \d+|-)             # bytesize       569
           \ \"(?<referer>      [^\"]*)\"          # referer        "http://infochimps.org/search?query=CAC"
           \ \"(?<user_agent>   [^\"]*)\"          # user_agent     "Mozilla/5.0 (Windows; U; Windows NT 5.1; fr; rv:1.9.0.16) Gecko/2009120208 Firefox/3.0.16"
          \z}x

end
