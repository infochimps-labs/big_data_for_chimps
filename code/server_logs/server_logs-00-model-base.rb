class Logline
  include Gorillib::Model
  include Gorillib::Model::PositionalFields

  field :ip_address,    String
  field :rfc_1413,      String
  field :userid,        String
  #
  field :requested_at,  Time
  field :http_method,   String
  field :path,          String
  field :protocol,      String
  field :response_code, Integer
  field :bytesize,      Integer, blankish: ['', nil, '-']
  field :referer,       String
  field :user_agent,    String
end
