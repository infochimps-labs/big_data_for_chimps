class Logline
  # Use the regex to break line into fields
  # Emit each record as flat line
  def self.parse(line)
    m = LOG_RE.match(line.chomp) or return BadRecord.new('no match', line)
    new(* m.captures)
  end
end
