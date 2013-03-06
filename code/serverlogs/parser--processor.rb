class ApacheLogParser < Wukong::Streamer::Base
  include Wukong::Streamer::EncodingCleaner

  def process(rawline)
    logline = Logline.parse(rawline)
    yield [logline.to_tsv]
  end
end

Wukong.run( ApacheLogParser )
