

time cat /data/rawd/sports/baseball/baseball_databank/csv/Master.csv |
  tail -n +2 | cut -f 7,13,14,15 |
  ruby -ne '$_.chomp! ; arr = $_.split(",") ; [ :ct, :ct, :fn, :ln  ].zip(arr).each{|type, str| str = str.to_s ;
    ups = str.gsub(/[^A-Z]/,"").downcase;
    (str+ups).split(//).each{|char| puts [type, char].join("\t") } }' |
  ruby -e 'counts = Hash.new(0) ;
    $stdin.readlines.each{|char| char.chomp! ; counts[char] += 1 } ;
    tot = 0 ;
    counts.each{|char, cc| tot += cc } ; result = counts.sort.each{|char, cc| puts [char, cc, (1_000_000 * cc / tot)].join("\t") }' |
    sort -nk2

time cat /data/rawd/sports/baseball/baseball_databank/csv/Master.csv | tail -n +2 | cut -f 7,13,14,15 -d, | ruby -ne '$_.chomp! ; arr = $_.split(",") ; [ :ct, :ct, :fn, :ln  ].zip(arr).each{|type, str| str = str.to_s ; ups = "" and str.gsub(/[^A-Z]/,"").downcase ; (str+ups).split(//).each{|char| puts [type, char].join("\t") } }' > /foo/part1.tsv

time cat /foo/part1.tsv |
  ruby -e 'counts = { "fn" => Hash.new(0), "ct" => Hash.new(0), "ln" => Hash.new(0) } ; tot = Hash.new(0) ;
  $stdin.each{|str| type, char = str.chomp.split("\t") ; counts[type][char] += 1 ;  tot[type] += 1 } ; result = counts.each{|type, hsh| hsh.each{|char, cc| puts [type, char, cc, (1_000_000 * cc / tot[type])].join("\t") } }'

time cat /foo/part1.tsv |   ruby -e 'counts = { "fn" => Hash.new(0), "ct" => Hash.new(0), "ln" => Hash.new(0) } ; tot = Hash.new(0) ; $stdin.each{|str| type, char = str.chomp.split("\t") ; counts[type][char] += 1 ;  tot[type] += 1 } ; ( ("A".."Z").to_a + ("a".."z").to_a ).flatten.each{|char| puts [char, %w[fn ln ct].map{|type| cc = counts[type][char] ; [ (1_000_000 * cc / tot[type]) ] }].flatten.join("\t") } '

head /usr/share/dict/words

ruby -ne '$_.chomp! ; ["di", $_].each{|type, str| str = str.to_s ; ups = "" and str.gsub(/[^A-Z]/,"").downcase ; (str+ups).split(//).each{|char| puts [type, char].join("\t") } }' > /foo/part1.tsv

time cat /tmp/dict_chars.tsv |   ruby -e 'counts = { "fn" => Hash.new(0), "ct" => Hash.new(0), "ln" => Hash.new(0) , "di" => Hash.new(0) } ; tot = Hash.new(0) ; $stdin.each{|str| type, char = str.chomp.split("\t") ; counts[type][char] += 1 ;  tot[type] += 1 } ; ( ("A".."Z").to_a + ("a".."z").to_a ).flatten.each{|char| puts [char, %w[di].map{|type| cc = counts[type][char] ; [ cc, (1_000_000 * cc / tot[type]) ] }].flatten.join("\t") } '

time cat /usr/share/dict/words   | egrep -v '[A-Z]'    | ruby -ne '$_.chomp! ; [["di", $_]].each{|type, str| str.to_s.downcase.split(//).each{|char| puts "#{type}\t#{char}" } }' >  /tmp/dict_chars.tsv
time cat /data/rawd/lang/corpora/scrabble/TWL06.txt    | ruby -ne '$_.chomp! ; [["di", $_]].each{|type, str| str.to_s.downcase.split(//).each{|char| puts "#{type}\t#{char}" } }' >  /tmp/twl_chars.tsv
time cat /data/rawd/sports/baseball/baseball_databank/csv/Master.csv | tail -n +2 | cut -f 7,13,14,15 -d, | ruby -ne '$_.chomp! ; arr = $_.split(",") ; [ :ct, :ct, :fn, :ln  ].zip(arr).each{|type, str| str.to_s.downcase.split(//).each{|char| puts "#{type}\t#{char}" } }' > /tmp/name_chars.tsv

time cat /tmp/{dict,name}_chars.tsv |   ruby -e 'counts = { "fn" => Hash.new(0), "ct" => Hash.new(0), "ln" => Hash.new(0), "di" => Hash.new(0) } ; tot = Hash.new(0) ; $stdin.each{|str| type, char = str.chomp.split("\t") ; counts[type][char] += 1 ;  tot[type] += 1 } ; ("a".."z").each{|char| puts [char, %w[di fn ln ct].map{|type| (1_000_000 * counts[type][char] / tot[type]) }, %w[di fn ln ct].map{|type| ( (counts[type][char].to_f/tot[type]) / (counts["di"][char].to_f / tot["di"])).round(3) } ].flatten.join("\t") } ' | wu-lign

The first four numeric columns give the parts-per-million frequency; the last four give the frequency relative to /dict/words.

char      dict  firstnm lastnm   city    oxford wikiped   dict  firstnm lastnm   city
a        82693   83174   86056  101718    84966   81670   1.0    1.006   1.041   1.230
b        18088   36148   25439   22552    20720   14920   1.0    1.998   1.406   1.247
c        45730   36762   36333   38344    45388   27820   1.0     .804    .795    .839
d        29983   44211   30565   29725    33844   42530   1.0    1.475   1.019    .991
e       105563  110313  110189   86327   111607  127020   1.0    1.045   1.044    .818
f        11330   14392   12142   10482    18121   22280   1.0    1.270   1.072    .925
g        21245   20341   24874   24233    24705   20150   1.0     .957   1.171   1.141
h        27624   34095   38517   31084    30034   60940   1.0    1.234   1.394   1.125
i        87844   68572   57447   67192    75448   69660   1.0     .781    .654    .765
j         1229   37045    4848    2708     1965    1530   1.0    3.135   3.944   2.203
k         7027   30715   21771   14827    11016    7720   1.0    4.371   3.098   2.110
l        58633   62980   69437   73351    54893   40250   1.0    1.074   1.184   1.251
m        30817   37389   35751   24714    30129   24060   1.0    1.213   1.160    .802
n        70471   64614   78316   80765    66544   67490   1.0     .917   1.111   1.146
o        76411   68130   71022   83213    71635   75070   1.0     .892    .929   1.089
p        35005   10865   15809   21114    31671   19290   1.0     .310    .452    .603
q         1683     319    1037     878     1962     950   1.0     .190    .616    .522
r        72293   83322   89024   62110    75809   59870   1.0    1.153   1.231    .859
s        62119   30605   62683   58764    57351   63270   1.0     .493   1.009    .946
t        69146   40093   45583   57041    69509   90560   1.0     .580    .659    .825
u        39260   19100   24292   24540    36308   27580   1.0     .487    .619    .625
v         9280   11578    8415   13618    10074    9780   1.0    1.248    .907   1.467
w         6381    8222   18154   16695    12899   23600   1.0    1.289   2.845   2.616
x         3114    2286    1197    1776     2902    1500   1.0     .734    .384    .571
y        23431   39319   19528   15892    17779   19740   1.0    1.678    .833    .678
z         3589    1917    9806    1151     2722     740   1.0     .534   2.732    .321

j, k, w and b are very over-represented in names
Z is very over-represented (2.7x) in last names, possibly because of the number of Hispanic and Latin American players.

Here is a table taken from http://www.oxforddictionaries.com/words/what-is-the-frequency-of-the-letters-of-the-alphabet-in-english and from https://en.wikipedia.org/wiki/Letter_frequency#Relative_frequencies_of_letters_in_the_English_language

char    % dictionary    % prose         % first names   % excess
a         8.49            8.16           8.31            1.01
b         2.07            1.49           3.61            2.00
c         4.53            2.78           3.67             .80
d         3.38            4.25           4.42            1.48
e        11.16           12.70          11.03            1.05
f         1.81            2.22           1.43            1.27
g         2.47            2.01           2.03             .96
h         3.00            6.09           3.40            1.23
i         7.54            6.96           6.85             .78
j          .19            0.15           3.70            3.14
k         1.10            0.77           3.07            4.37
l         5.48            4.02           6.29            1.07
m         3.01            2.40           3.73            1.21
n         6.65            6.74           6.46             .92
o         7.16            7.50           6.81             .89
p         3.16            1.92           1.08             .31
q          .19            0.09            . 3             .19
r         7.58            5.98           8.33            1.15
s         5.73            6.32           3.06             .49
t         6.95            9.05           4.00             .58
u         3.63            2.75           1.91             .49
v         1.00            0.97           1.15            1.25
w         1.28            2.36            .82            1.29
x          .29            0.15            .22             .73
y         1.77            1.97           3.93            1.68
z          .27            0.07            .19             .53

    chars_mapper do
      def recordize(line) line.split(",").slice(5,12,13,14) }
      def process *args
        %w[ ct, ct, fn, ln ].zip(args).each do |attr, str|
          str.chars.each{|char| yield([attr, char] }
        end
    end

    chars_reducer do
      def each_group(key, group, &:blk)
        yield [key, group.count]
      end
    end
