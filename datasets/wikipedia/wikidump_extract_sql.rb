#!/usr/bin/env ruby
require 'rubygems'
require 'wukong'
require 'faster_csv'
require 'oniguruma'

class ExtractPageInfo < Wukong::Streamer::LineStreamer
  QUOTED_QUOTE_RE = Oniguruma::ORegexp.new(%q{(?<!\\\\)\\\\'}) #'

  # def initialize *args
  #   super *args
  #   self.in_record = false
  # end

  #
  #
  def process line
    return unless line.gsub!(/^INSERT INTO `\w+` VALUES \(/,"")
    warn "bad ending" unless line.gsub!(/\);?$/, '')
    line.split(/\),\(/).each do |tuple|
      begin
        QUOTED_QUOTE_RE.gsub!(tuple, "''")
        emit FasterCSV.parse_line(tuple, :quote_char => "'")
      rescue FasterCSV::MalformedCSVError => e
        warn "#{e}: #{tuple}"
      end

    end
  end
end

# Execute the script
Wukong::Script.new(
  ExtractPageInfo,
  nil
  ).run
