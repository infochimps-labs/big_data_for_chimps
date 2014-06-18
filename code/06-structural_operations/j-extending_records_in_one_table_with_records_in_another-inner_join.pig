IMPORT 'common_macros.pig'; %DEFAULT data_dir '/data/rawd'; %DEFAULT out_dir '/data/out/baseball';

-- You will need to first generate the career stats by running
-- 06-structural_operations/b-summarizing_aggregate_statistics_of_a_group.pig:DESCRIBE
bat_careers = LOAD_RESULT('bat_careers');
peeps       = load_people();

-- ***************************************************************************
--
-- === Joining Records in a Table with Corresponding Records in Another Table (Inner Join)
--
-- // alternate title??: Matching Records Between Tables (Inner Join)

-- ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
--
-- ==== Joining Records in a Table with Directly Matching Records from Another Table (Direct Inner Join)
--

-- There is a stereotypical picture in baseball of a "slugger": a big fat man
-- who comes to plate challenging your notion of what an athlete looks like, and
-- challenging the pitcher to prevent him from knocking the ball for multiple
-- bases (or at least far enough away to lumber up to first base). To examine
-- the correspondence from body type to ability to hit for power (i.e. high
-- SLG), we will need to join the `people` table (listing height and weight)
-- with their hitting stats.
--
--
--
fatness = FOREACH peeps GENERATE
  player_id, name_first, name_last,
  height_in, weight_lb;
-- lightly filter out players without statistically significant careers:
-- (1000 PA is about two seasons worth of regular play. (TODO check, and make choice uniform)
slugging_stats = FOREACH (FILTER bat_careers BY (PA > 1000))
  GENERATE player_id, SLG;

-- The syntax of the join statement itself shouldn't be much of a surprise:
slugging_fatness_join = JOIN
  fatness        BY player_id,
  slugging_stats BY player_id;

LIMIT slugging_fatness_join 20; DUMP @;
-- ...

-- Each output record from a JOIN simply consist of all the fields from the first table, in their original order, followed by the fields from a matching record in the second table, all in their original order. If you held up a piece of paper covering the right part of your screen you'd think you were looking at the original table.
-- (This is in contrast to the records from a COGROUP: records from each table become elements in a corresponding bag, and so we would use `parks.park_name` to get the values of the park_name field from the parks bag.
-- one thing you'll notice in the snippet is the notation `bat_careers::player_id`.

DESCRIBE slugging_fatness_join;
-- {...}

-- as a consequence of flattening records from the fatness table next to records from the slugging_stats table, the two tables each contribute a field named `player_id`. Although _we_ privately know that both fields have the same value, Pig is right to insist on an unambiguous reference. The schema helpfully carries a prefix on each field disambiguating its table of origin.

So having done the join, we finish by preparing the output:

FOREACH(JOIN fatness BY player_id, slugging_stats BY player_id) {
  BMI = ROUND_TO(703.0*weight_lb/(height_in*height_in),1) AS BMI;
  GENERATE bat_careers::player_id, name_first, name_last,
    SLG, height_in, weight_lb, BMI;
};

-- We added a field for BMI (Body Mass Index), a simple measure of body type found by diving a person's weight by their height squared (and, since we're stuck with english units, multiplying by 703 to convert to metric). Though BMI
-- can't distinguish between 180 pounds of muscle and 180 pounds of flab, it reasonably controls for weight-due-to-tallness vs weight-due-to-bulkiness:
-- beanpole Randy Johnson (6'10"/2.1m, 225lb/102kg) and pocket rocket Tim Raines (5'8"/1.7m, 160lb/73kb) both have a low BMI of 23; Babe Ruth (who in his later days was 6'2"/1.88m 260lb/118kb) and Cecil Fielder (of whom Bill James wrote "...his reported weight of 261 leaves unanswered the question of what he might weigh if he put his other foot on the scale") both have high BMIs well above 30 footnote:[The dataset we're using unfortunately only records players' weights at the start of their career, so you will see different values listed for Mr. Fielder and Mr. Ruth.]


-- ------
-- SELECT bat.player_id, peep.nameCommon, begYear,
--     peep.weight, peep.height,
--     703*peep.weight/(peep.height*peep.height) AS BMI, -- measure of body type
--     PA, OPS, ISO
--   FROM bat_career bat
--   JOIN people peep ON bat.player_id = peep.player_id
--   WHERE PA > 500 AND begYear > 1910
--   ORDER BY BMI DESC
--   ;
-- ------

-- === How a Join Works

So that you can effectively reason about the behavior of a JOIN, it's important that you have the following two-and-a-half ways to think about its operation: (a) as the equivalent of a COGROUP-and-FLATTEN; and (b) as the underlying map-reduce job it produces.

-- ==== A Join is a COGROUP+FLATTEN

-- ==== A Join is a Map/Reduce Job with a secondary sort on the Table Name

The way to perform a join in map-reduce is similarly a particular application of the COGROUP we stepped through above. Even still, we'll walk through it mostly on its own --

The mapper receives its set of input splits either from the bat_careers table or from the peep table and makes the appropriate transformations. Just as above (REF), the mapper knows which file it is receiving via either framework metadata or environment variable in Hadoop Streaming. The records it emits follow the COGROUP pattern: the join fields, anointed as the partition fields; then the index labeling the origin file, anointed as the secondary sort fields; then the remainder of the fields. So far this is just a transform (FOREACH) inlined into a cogroup.

------
mapper do
  self.processes_models
  config.partition_fields 1 # player_id
  config.sort_fields      2 # player_id, origin_key
RECORD_ORIGINS = [
  /bat_careers/ => ['A', Baseball::BatCareer],
  /players/     => ['B', Baseball::Player],
]
def set_record_origin!
  RECORD_ORIGINS.each do |origin_name_re, (origin_index, record_klass)|
    if config[:input_file]
      [@origin_key, @record_klass] = [origin_index, record_klass]
      return
    end
  end
  # no match, fail
  raise RuntimeError, "The input file name #{config[:input_file]} must match one of #{RECORD_ORIGINS.keys} so we can recognize how to handle it."
end
def start(*) set_record_origin! ; end
def recordize(vals) @record_klass.receive(vals)
def process(record)
  case record
  when CareerStats
    yield [rec.player_id, @origin_idx, rec.slg]
  when Player
    yield [rec.player_id, @origin_key, rec.height_in, rec.weight_lb]
  else raise "Impossible record type #{rec.class}"
  end
end
end

reducer do
  def gather_records(group, origin_key)
    records = []
    group.each do |*vals|
      if vals[1] != origin_key # We hit start of next table's keys
        group.shift(vals)      # put it back before Mom notices
        break                  # and stop gathering records
      end
      records << vals
    end
    return records
  end


  BMI_ENGLISH_TO_METRIC = 0.453592 / (0.0254 * 0.254)
  def bmi(ht, wt)
    BMI_ENGLISH_TO_METRIC * wt / (ht * ht)
  end

  def process_group(group)
    players = gather_records(group, 'A'
    # remainder are slugging stats
    group.each do |player_id, _, slg|
      players.each do |player_id,_, height_in, weight_lb|
        # Pig would output all the fields from the JOIN,
        # but we're inlining the follow-on FOREACH as well
        yield [player_id, slg, height_in, weight_lb, bmi(height_in, weight_lb)]
      end
    end
  end
end

-- TODO-qem should I show the version that has just the naked join-like output ie. All the fields from each table, not including the BMI, as per slugging_fatness_join? And if so do I show it as well or instead?

-- The output of the Join job will have one record for each discrete combination of A and B. As you will notice in our Wukong version of the Join, the secondary sort ensures that for each key the reducer receives all the records for table A strictly followed by all records for table B. We gather all the A records in to an array, then on each B record emit the A records stapled to the B records. All the A records have to be held in memory at the same time, while all the B records simply flutter by; this means that if you have two datasets of wildly different sizes or distribution, it is worth ensuring the Reducer receives the smaller group first. In map/reduce, the table with the largest number of records per key should be assigned the last-occurring field group label; in Pig, that table should be named last in the JOIN statement.
--

stats_and_fatness = FOREACH (JOIN fatness BY player_id, stats BY player_id)
  GENERATE fatness::player_id..BMI, stats::n_seasons..OPS;

STORE_TABLE(stats_and_fatness, 'stats_and_fatness');

-- ===== Exercise
--
-- Exercise: Explore the correspondence of weight, height and BMI to SLG using a
-- medium-data tool such as R, Pandas or Excel. Spoiler alert: the stereotypes
-- of the big fat slugger is quire true.

-- ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
--
-- ==== Disambiguating Field Names With `::`
--

-- ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
--
-- ==== Handling Nulls in Joins
--

-- (add note) Joins on null values are dropped even when both are null. Filter nulls. (I can't come up with a good example of this)
-- (add note) in contrast, all elements with null in a group _will_ be grouped as null. This can be dangerous when large number of nulls: all go to same reducer

-- Other topics in JOIN-land:
--
-- * See advanced joins: bag left outer join from DataFu
-- * See advanced joins: Left outer join on three tables: http://datafu.incubator.apache.org/docs/datafu/guide/more-tips-and-tricks.html
-- * See Time-series: Range query using cross
-- * See Time-series: Range query using prefix and UDFs (the ip-to-geo example)
-- * See advanced joins: Sparse joins for filtering, with a HashMap (replicated)
-- * Out of scope: Bitmap index
-- * Out of scope: Bloom filter joins
-- * See time-series: Self-join for successive row differences
