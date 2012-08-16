class Logline
  include Gorillib::Model
  include Gorillib::Model::PositionalFields

  field :ip,            String
  field :junk1,         String
  field :junk2,         String
  #
  field :visit_time,    Time
  field :http_method,   String
  field :path,          String
  field :protocol,      String
  field :response_code, Integer
  field :size,          Integer, blankish: ['', nil, '-']
  field :referer,       String
  field :ua,            String
  field :cruft,         String

  # Use the regex to break line into fields
  # Emit each record as flat line
  def self.parse(line)
    m = LOG_RE.match(line.chomp) or return BadRecord.new('no match', line)
    new(* m.captures)
  end
end
