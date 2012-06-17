Wukong.processor(:flatten_wikidump_xml) do
  doc <<-DOC
    ChimpMARK-2010 -- meta/prepare/wikidump/flatten_xml.rb

    Flattens the wikipedia 'enwiki-latest-pages-articles.xml.gz' into a
    one-line-per-record heap.

       bin/prepare/wikidump/flatten_xml.rb --rm --run \
         /data/source/download.wikimedia.org/enwiki/20100622-expanded/enwiki-20100622-pages-articles.xml
         /data/rawd/wikidump/articles

    <page>
      <title>Anarchism</title>
      <id>12</id>
      <revision>
        <id>370845941</id>
        <timestamp>2010-06-29T20:14:56Z</timestamp>
        <contributor>
          <username>Centographer</username>
          <id>12640258</id>
        </contributor>
        <comment>clarifying not ordinary anarcho-socialism</comment>
        <text xml:space="preserve">
          ...snip ...
        </text>
      </revision>
    </page>

   DOC
  START_OF_RECORD=%r{\A\s*<page>}
  END_OF_RECORD=%r{\A\s*</page>}

  #
  # Set the XML tag to use in the constants START_OF_RECORD and END_OF_RECORD
  #
  # This will output the content between each start/end pair in a single line
  # and eliminate content not enclosed in a start/end pair
  #
  # This makes NO ATTEMPT at parsing or at any kind of smart behavior --
  # it does something simple and stupid that happens to work because of the
  # special format of the one file it's meant to process.
  #
  def process line
    case
    when (line =~ START_OF_RECORD)
      puts "\n!!!#{@in_record.inspect}\n" if @in_record
      line.gsub!(/^\s+/,'')
      print line.chomp
      @in_record = true
    when (line =~ END_OF_RECORD)
      puts line
      @in_record = false
    else
      print(line.chomp, '&#10;') if self.in_record
    end
  end
end


# Execute the script
Wukong::Script.new(
  FlattenXml,
  nil,
  :split_on_xml_tag => 'page',
  :min_split_size   => '536870912'
  ).run
