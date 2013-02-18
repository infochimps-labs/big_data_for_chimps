require 'wu/munging'

class Logline
  # Use the regex to break line into fields
  # Emit each record as flat line
  def self.parse(line)
    mm = raw_regex.match(line.chomp) or return BadRecord.new('no match', line)
    new(mm.captures_hash)
  end
end
