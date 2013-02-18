class Logline

  include Gorillib::Model

  field :ip_address,    String
  field :requested_at,  Time
  field :http_method,   String,  doc: "GET, POST, etc"
  field :uri_str,       String,  doc: "Combined path and query string of request"
  field :protocol,      String,  doc: "eg 'HTTP/1.1'"
  #
  field :response_code, Integer, doc: "HTTP status code (j.mp/httpcodes)"
  field :bytesize,      Integer, doc: "Bytes in response body", blankish: ['', nil, '-']
  field :referer,       String,  doc: "URL of linked-from page. Note speling."
  field :user_agent,    String,  doc: "Version info of application making the request"

  def visitor_id ; ip_address ; end

end
