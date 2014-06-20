IMPORT 'common_macros.pig'; %DEFAULT data_dir '/data/rawd'; %DEFAULT out_dir '/data/out/baseball';

bat_seasons = load_bat_seasons();
peeps       = load_people();
teams       = load_teams();
park_teams   = load_park_teams();

-- ***************************************************************************
--
-- === Selecting Rows that Satisfy a Condition @modern_stats
--

-- Only Modern seasons
modern_stats = FILTER bat_seasons BY (year_id >= 1900);


-- ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
--
-- ==== Selecting Records that Satisfy Multiple Conditions @modsig_stats
--

-- Modern seasons of more than 450 PA
modsig_stats = FILTER bat_seasons BY
  (PA >= 450) AND (year_id >= 1900) AND ((lg_id == 'AL') OR (lg_id == 'NL'));


-- ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
--
-- ==== Selecting Records that Match a Regular Expression @funnychars
--

-- Doesn't start with a capital letter, or contains a non-word non-space character
funnychars = FILTER people BY
  (name_last  MATCHES '^([^A-Z]|.*[^\\w\\s]).*') OR
  (name_first MATCHES '^([^A-Z]|.*[^\\w\\s]).*');


-- ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
--
-- ==== Controlling Case Sensitivity and Other Regular Expression Modifiers  @namesakes
--

-- Name contains a 'Q', 'Flip', or anything in the Philip/Phillip/... family
-- (?i) means "case insensitive"
namesakes = FILTER people BY (name_first MATCHES '(?i).*(q|flip|phil+ip).*');

-- ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
--
-- ==== Selecting Records against a Fixed List of Lookup Values
--

al_east_parks = FILTER park_teams BY
  team_id IN ('BAL', 'BOS', 'CLE', 'DET', 'ML4', 'NYA', 'TBA', 'TOR', 'WS2');


STORE_TABLE(modern_stats,  'modern_stats');
STORE_TABLE(modsig_stats,  'modsig_stats');
STORE_TABLE(funnychars,    'funnychars');
STORE_TABLE(namesakes,     'namesakes');
STORE_TABLE(al_east_parks, 'al_east_parks');


IMPORT 'common_macros.pig'; %DEFAULT data_dir '/data/rawd'; %DEFAULT out_dir '/data/out/baseball';

peeps       = load_people();
games             = load_games();

-- ***************************************************************************
--
-- === Projecting Chosen Columns from a Table by Name
--

game_scores = FOREACH games GENERATE
  away_team_id, home_team_id, home_runs_ct, away_runs_ct;

-- ***************************************************************************
--
-- ==== Using a FOREACH to select, rename and reorder fields @win_loss_union
--

games_a = FOREACH games GENERATE
  home_team_id AS team,     year_id,
  home_runs_ct AS runs_for, away_runs_ct AS runs_against, 1 AS is_home:int;
games_b = FOREACH games GENERATE
  away_team_id AS team,     year_id,
  away_runs_ct AS runs_for, home_runs_ct AS runs_against, 0 AS is_home:int;

team_scores = UNION games_a, games_b;

DESCRIBE team_scores;
-- team_scores: {team: chararray,year_id: int,runs_for: int,runs_against: int,is_home: int}

-- ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
STORE_TABLE(game_scores, 'game_scores');
STORE_TABLE(team_scores, 'team_scores');

-- Example use: the total runs scored for and against in each team's history.
team_season_runs = FOREACH (GROUP team_scores BY team_id) GENERATE
  group AS team_id, SUM(runs_for) AS R, SUM(runs_against) AS RA;
IMPORT 'common_macros.pig'; %DEFAULT data_dir '/data/rawd'; %DEFAULT out_dir '/data/out/baseball';

bat_seasons = load_bat_seasons();

-- ***************************************************************************
--
-- === Selecting a Random Sample of Records
--

some_seasons_samp = SAMPLE bat_seasons 0.0625;

--
-- ==== Extracting a Consistent Sample of Records by Key
--

-- The seasons for a given player will either all be kept or all be rejected.

DEFINE Hash  datafu.pig.hash.Hasher('murmur3-32');

plhash_seasons = FOREACH bat_seasons GENERATE
  Hash(player_id) AS keep_hash, *;

some_seasons_bypl  = FOREACH (
    FILTER plhash_seasons BY (STARTSWITH(keep_hash, '0'))
  ) GENERATE $0..;


bat_seasons_md = LOAD '$rawd/sports/baseball/bats_lite.tsv'
  USING PigStorage('\t', '-tagMetadata') AS (
  metadata: map[],
  player_id:chararray, year_id:int,
  team_id:chararray,   lg_id:chararray,
  age: int,  G:int,     PA:int,    AB:int,
  HBP:int,   SH: int,   BB:int,    H:int,
  h1B:int,   h2B:int,   h3B:int,   HR:int,
  R:int,     RBI:int,   OBP:float, SLG:float
  );

bat_seasons_md = RANK bat_seasons_md;

rechash_seasons = FOREACH bat_seasons_md GENERATE
  Hash((chararray)CONCAT(metadata#'pathname', (chararray)metadata#'sp_index', (chararray)rank_bat_seasons_md)) AS keep_hash, *;

some_seasons_hash  = FOREACH (
    FILTER rechash_seasons BY (STARTSWITH(keep_hash, '0'))
  ) GENERATE $0..;


STORE_TABLE(some_seasons_samp,   'some_seasons_samp');
STORE_TABLE(some_seasons_bypl,   'some_seasons_bypl');
STORE_TABLE(some_seasons_hash,   'some_seasons_hash');
IMPORT 'common_macros.pig'; %DEFAULT data_dir '/data/rawd'; %DEFAULT out_dir '/data/out/baseball';

bat_seasons = load_bat_seasons();

-- ***************************************************************************
--
-- === Selecting a Fixed Limit of Records
--

-- ==== 

-- The LIMIT statement 
-- Without some preceding operation to set the records in a determined order, it's rarely used except to extract a snippet of data for development. Let's 

-- Choose an arbitrary 25 sequential records. See chapter 6 for something more interesting.
some_players = LIMIT bat_seasons 25;

STORE_TABLE(some_players, 'some_players');

--
-- ==== LIMIT .. DUMP
--

-- The main use of a LIMIT statement, outside of an ORDER BY..LIMIT stanza, is
-- before dumping data

-- We hope that some day the DUMP command gains an intrinsic LIMIT
-- capability. Until then, you can try this:
=> LIMIT bat_seasons 25; DUMP @;

-- Keep in mind that the presence anywhere of a DUMP command has hidden
-- consequences, including disabling multi-query execution.


IMPORT 'common_macros.pig'; %DEFAULT data_dir '/data/rawd'; %DEFAULT out_dir '/data/out/baseball';

bat_seasons = load_bat_seasons();

-- ***************************************************************************
--
-- === Transforming Records Individually
--

bat_seasons = LOAD '/tmp/bat_null.tsv' USING PigStorage('\t', '--null_string \\N')   AS (
    player_id:chararray, name_first:chararray, name_last:chararray,     --  $0- $2
    year_id:int,        team_id:chararray,     lg_id:chararray,         --  $3- $5
    age:int,  G:int,    PA:int,   AB:int,  HBP:int,  SH:int,   BB:int,  --  $6-$12
    H:int,    h1B:int,  h2B:int,  h3B:int, HR:int,   R:int,    RBI:int  -- $13-$19
    ) ;

bat_seasons = FILTER bat_seasons BY PA > 0 AND AB > 0;
core_stats  = FOREACH bat_seasons {
  h1B  = H - (h2B + h3B + HR);
  HBP  = (HBP IS NULL ? 0 : HBP);
  TB   = h1B + 2*h2B + 3*h3B + 4*HR;
  OBP  = (H + BB + HBP) / PA;
  SLG  = TB / AB;
  OPS  = SLG + OBP;
  GENERATE
    player_id, name_first, name_last,   --  $0- $2
    year_id,   team_id,   lg_id,        --  $3- $5
    age,  G,   PA,  AB,   HBP, SH,  BB, --  $6-$12
    H,    h1B, h2B, h3B,  HR,  R,  RBI, -- $13-$19
    SLG, OBP, OPS;                      -- $20-$22
};

-- -- ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
-- --
--
-- junk_drawer = FOREACH bat_seasons {
--
--   -- Concatenating Several Values into a Single String
--   full_name  = CONCAT(name_first, ' ', name_last);
--   -- Converting the Lettercase of a String
--   name_shouty = UPPER(name_last);
--
--   -- Extracting Characters from a String by Offset
--   initials = CONCAT(
--     SUBSTRING(name_first, 0, 1), '. ',
--     SUBSTRING(name_first, 0, 1), '.');
--   --   The first index in SUBSTRING gives the start, counting from zero.
--   --   The second index gives the _character after the end_.
--   -- Select second through fourth characters with `1, 5`. Makes sense to me!
--   chars234 = SUBSTRING(name_first, 1, 5);
--
--   --   Selecting past the end of a string just takes what's there to take.
--   tail_end     = SUBSTRING(player_id, 6, 99);
--   way_past_end = SUBSTRING(player_id, 69, 99);
--
--   -- Handling Special Characters in Strings
--   string_that_will_cause_problems = 'here is a newline:\n'


-- ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
--
-- ==== Transforming Nulls into Real Values
--

-- ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
--
-- ==== Working with Null Values
--

-- ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
--
-- ==== Formatting a String According to a Template
--

-- ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
--
-- ==== Replacing Sections of a String using a Regular Expression
--


-- ==== Choosing a Value Conditionally

-- demonstrate case and ternary statements (combine/move demonstration in filter section?)

-- ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
--
-- === A Nested FOREACH Allows Intermediate Expressions


STORE_TABLE(core_stats, 'core_stats');
IMPORT 'common_macros.pig'; %DEFAULT data_dir '/data/rawd'; %DEFAULT out_dir '/data/out/baseball';

bat_seasons = load_bat_seasons();
peeps       = load_people();
teams       = load_teams();
park_teams   = load_park_teams();

-- ***************************************************************************
--
-- === Transforming Records with an External UDF
IMPORT 'common_macros.pig'; %DEFAULT data_dir '/data/rawd'; %DEFAULT out_dir '/data/out/baseball';

bat_seasons = load_bat_seasons();
peeps       = load_people();
teams       = load_teams();
park_teams   = load_park_teams();

-- ***************************************************************************
--
-- === Working With Strings
--

-- ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
--
-- ==== Splitting a String into Characters
--

-- ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
--
-- ==== Splitting a Delimited String into a Collection of Values
--

-- ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
--
-- ==== Finding a String's Size in Bytes or in Characters
--

-- ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
--
-- ==== Selecting Records that Match a Regular Expression Template
--

-- ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
--
-- ==== Replacing Sections of a String using a Regular Expression
--

-- ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
--
-- ==== Splitting Delimited Data into a Collection of Values
--

-- ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
--
-- ==== Formatting a String With a Template
--
--
IMPORT 'common_macros.pig'; %DEFAULT data_dir '/data/rawd'; %DEFAULT out_dir '/data/out/baseball';

bat_seasons = load_bat_seasons();
peeps       = load_people();
teams       = load_teams();
park_teams   = load_park_teams();

-- ***************************************************************************
--
-- === Assign an Increasing ID to Each Record in a Collection of Files
--
IMPORT 'common_macros.pig'; %DEFAULT data_dir '/data/rawd'; %DEFAULT out_dir '/data/out/baseball';

bat_seasons = load_bat_seasons();
peeps       = load_people();
teams       = load_teams();
park_teams   = load_park_teams();
franchises = load_franchises();

-- ***************************************************************************
--
-- === Expanding One Value Into a Tuple or Bag
--

-- ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
--
-- ==== Splitting a String into its Characters
--



-- ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
--
-- ==== Tokenizing the Words in a String
--

-- The TOKENIZE command
-- is a fast-and-dirty way to break a string into words.
-- (We'll demonstrate a much better tokenizer in the chapter on text data (REF)).
-- The return schema of tokenize is a bag of words footnote:[Technically, a bag of tuples each containing one word, as the direct contents of a bag are always tuples], which
-- FLATTEN turns into one record per word.
-- The follow-on code groups all words and produces the count of occurrences for each word; we'll explain how group and friends work in the next chapter

tn_toks    = FOREACH franchises
  GENERATE FLATTEN(TOKENIZE(franchName)) AS token;
tn_toks_ct = FOREACH (GROUP tn_toks BY token)
  GENERATE group AS token,
  COUNT_STAR(tn_toks.token) AS tok_ct;
-- Only retain the top million tokens
team_toks  = ORDER tn_toks_ct BY tok_ct DESC;
wp_toks    = LIMIT wp_toks 1000000;
rmf                   $out_dir/team_toks;
STORE team_toks INTO '$out_dir/team_toks';



IMPORT 'common_macros.pig'; %DEFAULT data_dir '/data/rawd'; %DEFAULT out_dir '/data/out/baseball';

bat_seasons = load_bat_seasons();
peeps       = load_people();
teams       = load_teams();
park_teams   = load_park_teams();

-- ***************************************************************************
--
-- === Generating Data by Distributing Assignments As Input

-- The best way to generate data in Hadoop is to prepare map inputs that represent assignments of what data to generate. There are two good examples of this pattern elsewhere in the book, so we won't try to contrive one here. One is the "poor-man's data loader" given in Chapter 3 (REF). The mapper input is a list of filenames or database queries; each mapper expands that trivial input into many rows of output. Another is the "self-inflicted DDOS" tool for stress-testing your website (REF). In that case, the mapper input is your historical weblogs, and the mapper output is formed from the web server response.IMPORT 'common_macros.pig'; %DEFAULT data_dir '/data/rawd'; %DEFAULT out_dir '/data/out/baseball';

bat_seasons = load_bat_seasons();
peeps       = load_people();
teams       = load_teams();
park_teams   = load_park_teams();

-- ***************************************************************************
--
-- === Generating a Sequence Using an Integer Table
--

-- What do you do when there isn't a natural assignment to seed from (eg generating fake data to test with), or when you're trying to enumerate values of a function (every IP address, or the sunrise and sunset times by date, or somesuch)? A table of integers -- yeah, just the lines 1, 2, 3, ... each on subsequent rows -- is astonishingly useful in many circumstances, and this is one of them. This Wukong map-reduce script will generate an arbitrary quantity of fake name, address and credit card data to use for testing purposes.

# seed the RNG with the index

http://www.ruby-doc.org/gems/docs/w/wukong-4.0.0/Wukong/Faker/Helpers.html
Faker::Config.locale = 'en-us'
Faker::Name.name #=> "Tyshawn Johns Sr."
Faker::PhoneNumber.phone_number #=> "397.693.1309"
Faker::Address.street_address #=> "282 Kevin Brook"
Faker::Address.secondary_address #=> "Apt. 672"
Faker::Address.city #=> "Imogeneborough"
Faker::Address.zip_code #=> "58517"
Faker::Address.state_abbr #=> "AP"
Faker::Address.country #=> "French Guiana"
Faker::Business.credit_card_number #=> "1228-1221-1221-1431"
Faker::Business.credit_card_expiry_date #=> <Date: 2015-11-11 ((2457338j,0s,0n),+0s,2299161j)>

mapper do |line|
  idx = line.to_i
  offsets = [ line / C5, (line / C4) % 26, (line / C3) % 26, (line / C2) % 26, line % 26 ]
  chars = offsets.map{|offset| (ORD_A + offset).chr }
  yield chars.join
end


--
-- Generating random values is useful in many circumstances: anonymization, random sampling, test data generation and more. But generating truly random numbers is hard; and as we'll stress several times, it's always best to avoid having mappers that produce different inputs from run to run. An alternative approach is to prepare a giant table of pre-calculated indexed random numbers, and then use a JOIN (see next chapter) to decorate each record with a random value. This may seem hackish on first consideration, but it's the right call in many cases.


-- move to statistics
-- The website random.org makes available a large volume of _true_ randoms number 
-- http://www.random.org/files/

IMPORT 'common_macros.pig'; %DEFAULT data_dir '/data/rawd'; %DEFAULT out_dir '/data/out/baseball';

bat_seasons = load_bat_seasons();
peeps       = load_people();
teams       = load_teams();
park_teams   = load_park_teams();

-- ***************************************************************************
--
-- === Transposing Records into Attribute-Value Pairs
--

(Move to Statistics Chapter)IMPORT 'common_macros.pig'; %DEFAULT data_dir '/data/rawd'; %DEFAULT out_dir '/data/out/baseball';

bat_seasons = load_bat_seasons();
peeps       = load_people();
teams       = load_teams();
park_teams   = load_park_teams();

-- ***************************************************************************
--
-- === Flattening a Bag Generates Many Records
--


-- ***************************************************************************
--
-- === Flattening a Tuple Generates Many Columns

attr_strings = FOREACH people {
  fields_bag = {('fn', nameFirst), ('ln', nameLast), ('ct', birthCity), ('ct', deathCity)};
  GENERATE FLATTEN(fields_bag) AS (type:chararray, str:chararray);
  };
-- ('fn',Hank)
-- ('ln',Aaron)
-- ...

attr_chars = FOREACH (FILTER attr_strings BY str != '') {
  chars_bag = STRSPLITBAG(LOWER(str), '(?!^)');
  GENERATE type, FLATTEN(chars_bag) AS token;
  };
DESCRIBE attr_chars;

chars_ct   = FOREACH (GROUP attr_chars BY (type, token))
  GENERATE group.type, group.token, COUNT_STAR(attr_chars) AS ct
  ;

chars_freq = FOREACH (GROUP chars_ct BY type) {
  tot_ct = SUM(chars_ct.ct);
  GENERATE group AS type, tot_ct AS tot_ct, FLATTEN(chars_ct.(ct, token));
  };
chars_freq = FOREACH chars_freq GENERATE type, token, ct, (int)ROUND(1e6f*ct/tot_ct) AS freq:int;
DESCRIBE chars_freq;

rmf                    $out_dir/chars_freq;
STORE chars_freq INTO '$out_dir/chars_freq';


-- nf_chars = FOREACH bat_seasons GENERATE
--   FLATTEN(STRSPLITBAG(name_first, '(?!^)')) AS char;
-- chars_hist = FOREACH (GROUP nf_chars BY char) {
--   GENERATE group AS char, COUNT_STAR(nf_chars.char) AS ct;
-- };
-- chars_hist = ORDER chars_hist BY ct;
IMPORT 'common_macros.pig'; %DEFAULT data_dir '/data/rawd'; %DEFAULT out_dir '/data/out/baseball';

bat_seasons = load_bat_seasons();
peeps       = load_people();
teams       = load_teams();
park_teams   = load_park_teams();

-- ***************************************************************************
--
-- === Flattening a Tuple Generates Many Columns
IMPORT 'common_macros.pig'; %DEFAULT data_dir '/data/rawd'; %DEFAULT out_dir '/data/out/baseball';

bat_seasons = load_bat_seasons();
peeps       = load_people();
teams       = load_teams();
park_teams   = load_park_teams();

-- ***************************************************************************
--
-- === Splitting a Delimited String into a Collection of Values
--

-- TSV (tab-separated-values) is the Volkswagen Beetle of go-anywhere file formats: it's robust, simple, friendly and works everywhere. However, it has significant drawbacks, most notably that it can only store flat records: a member field with, say, an array type must be explicitly handled after loading. One common workaround for serializing an array type is to convert the array into a string, where each value is separated from the next using a delimiter -- a character that doesn't appear in any of the values. We'll demonstrate creating such a field in the next chapter (REF), and in fact we're going to sneak into the future and steal that section's output files.

team_parkslists = LOAD team_parklists AS (...)
xxx = FOREACH ... {
  parks = STRSPLITBAG(...);
  GENERATE ..., FLATTEN(parks), ...;
};

In other cases the value may not be a bag holding an arbitrarily-sized collection of values, but a tuple holding several composite fields. Among other examples, it's common to find addresses serialized this way. The people table has fields for (city,state,country) of both birth and death. We will demonstrate by first creating single birth_loc and death_loc fields, then untangling them.

people_shrunk = FOREACH people GENERATE
  player_id..birth_day,
  CONCAT(birth_city,'|', birth_state, '|', birth_country) AS birth_loc,
  death_year, death_month, death_day,
  CONCAT(death_city,'|', death_state, '|', death_country) AS death_loc,
  name_first.. ;

people_2 = FOREACH people_shrunk GENERATE
  player_id..birth_day,
  FLATTEN(STRSPLIT(birth_loc)) AS (birth_city, birth_state, birth_country),
  death_year, death_month, death_day,
  FLATTEN(STRSPLIT(death_loc)) AS (death_city, death_state, death_country),
  name_first.. ;
STORE_TABLE(people_2, 'people_2');

In this case we apply STRSPLIT, which makes a tuple (rather than STRSPLITBAG, which makes a bag). When we next apply FLATTEN to our tuple, it turns its fields into new columns (rather than if we had a bag, which would generate new rows). You can run the sample code to verify the output and input are identical.

-- TODO-qem (combine this with the later chapter? There's a lot going on there, so I think no, but want opinion)


IMPORT 'common_macros.pig'; %DEFAULT data_dir '/data/rawd'; %DEFAULT out_dir '/data/out/baseball';

bat_seasons = load_bat_seasons();
peeps       = load_people();
teams       = load_teams();
park_teams   = load_park_teams();

-- ***************************************************************************
--
-- === Directing Data Conditionally into Multiple Data Flows
--

-- TODO integrate prose

-- The most natural use of the SPLIT operator is when you really do require divergent processing flows. In the next chapter, you'll use a JOIN LEFT OUTER to geolocate (derive longitude and latitude from place name) records. That method is susceptible to missing matches, and so in practice a next step might be to apply a fancier but more costly geolocation tool. This is a strategy that arises often in advanced machine learning applications: run a first pass with a cheap algorithm that can estimate its error rate; isolate the low-confidence results for harder processing; then reunite the whole dataset.

-- Run the 06-.../Matching_records_imperfectly...
-- (Most records have been geolocated)

-- The syntax of the SPLIT command does not have an equals sign to the left of it; the new table aliases are created in its body.
SPLIT players_geoloced_some INTO 
  players_non_geoloced_us IF ((IsNull(lng) OR IsNull(lat)) AND (country_id == "US")),
  players_non_geoloced_fo IF ((IsNull(lng) OR IsNull(lat)),
  players_geoloced_a OTHERWISE;
  
-- ... Pretend we're applying a more costly / higher quality geolocation tool, rather than just sending all unmatched records to Disneyland...
players_geoloced_b = FOREACH players_non_geoloced_us GENERATE
  player_id..country_id,
  FLATTEN((Disney,land)) as (lng, lat);
-- ... And again, pretend we are not just sending all non-us to the Eiffel Tower.
players_geoloced_c = FOREACH players_non_geoloced_us GENERATE
  player_id..country_id,
  FLATTEN((Eiffel,tower)) as (lng, lat);

Players_geoloced = UNION alloftheabove;


-- The SPLIT statement is fairly rare in use, and though its own performance cost is low it can lead to proliferation of code paths and map-reduce jobs downstream. If the different streams receive significantly different schema or different processing downstream, the SPLIT statement is justified. But if you follow a SPLIT statement with parallel repeated stanzas applied to each stream, consider whether you're not better off using a case or ternary statement (REF); the "Partitioning Data By Keys into Multiple Files" (REF) pattern; the "Summarizing Multiple Subsets of a Table Simultaneously" (REF) pattern; or some other application of the "summing trick" (REF) introduced in the next chapter.IMPORT 'common_macros.pig'; %DEFAULT data_dir '/data/rawd'; %DEFAULT out_dir '/data/out/baseball';

bat_seasons = load_bat_seasons();
peeps       = load_people();
teams       = load_teams();
park_teams   = load_park_teams();

-- ***************************************************************************
--
-- === Partitioning Data into Multiple Files By Key
--

One reason you might find yourself splitting a table is to create multiple files on disk according to some key.

There might be many reasons to do this splitting, but one of the best is to accomplish the equivalent of what traditional database admins call "vertical partitioning". You are still free to access the table as a whole, but in cases where one field is over and over again used to subset the data, the filtering can be done without ever even accessing the excluded data. Modern databases have this feature built-in and will apply it on your behalf based on the query, but our application of it here is purely ad-hoc. You will need to specify the subset of files yourself at load time to take advantage of the filtering.

STORE events INTO '$out_dir/evs_away' 
  USING MultiStorage('$out_dir/evs_away','5'); -- field 5: away_team_id
STORE events INTO '$out_dir/evs_home' 
  USING MultiStorage('$out_dir/evs_home','6'); -- field 6: home_team_id


-- 
-- This script will run a map-only job with 9 map tasks (assuming 1GB+ of data and a 128MB block size). With MultiStorage, all Boston Red Sox (team id `BOS`) home games that come from say the fifth map task will go into `$out_dir/evs_home/BOS/part-m-0004` (contrast that to the normal case of  `$out_dir/evs_home/part-m-00004`). Each map task would write its records into the sub directory named for the team with the `part-m-` file named for its taskid index. 

-- Since most teams appear within each input split, each subdirectory will have a full set of part-m-00000 through part-m-00008 files. In our runs, we ended up with XXX output files -- not catastrophic, but (a) against best practices, (b) annoying to administer, (c) the cause of either nonlocal map tasks (if splits are combined) or proliferation of downstream map tasks (if splits are not combined). The methods of (REF) "Cleaning up Many Small Files" would work, but you'll need to run a cleanup job per team. Better by far is to precede the `STORE USING MultiStorage` step with a `GROUP BY team_id`. We'll learn all about grouping next chapter, but its use should be clear enough: all of each team's events will be sent to a common reducer; as long as the Pig `pig.output.lazy` option is set, the other reducers will not output files.

events_by_away = FOREACH (GROUP events BY away_team_id) GENERATE FLATTEN(events);
events_by_home = FOREACH (GROUP events BY home_team_id) GENERATE FLATTEN(events);
STORE events_by_away INTO '$out_dir/evs_away-g' 
  USING MultiStorage('$out_dir/evs_away-g','5'); -- field 5: away_team_id
STORE events_by_home INTO '$out_dir/evs_home-g' 
  USING MultiStorage('$out_dir/evs_home-g','6'); -- field 6: home_team_id
-- cp $data_dir/sports/baseball/events/.pig_schema $out_dir/evs_away-g

Lastly, a couple notes about MultiStorage. It only partitions by a single key field in each record, and that key will is unavoidably written to disk along with the records -- you need to be OK with it sticking around. If the key is null, the word 'null' will be substituted without warning. (TODO check). You can produce compressed output by supplying an additional option; see the documentation. Lastly, it does not accept PigStorage's advanced options such as writing schema files or overwriting output.IMPORT 'common_macros.pig'; %DEFAULT data_dir '/data/rawd'; %DEFAULT out_dir '/data/out/baseball';

bat_seasons = load_bat_seasons();

-- ***************************************************************************
--
-- === Partitioning Data into Uniform Chunks
--

-- note this should come after the MultiStorage script.

-- An ORDER BY statement with parallelism forced to (output size / desired chunk size) will give you _roughly_ uniform chunks, 

%DEFAULT chunk_size 10000
;

-- Supply enough keys to rank to ensure a stable sorting
bat_seasons_ranked  = RANK bat_seasons BY (player_id, year_id)
bat_seasons_chunked = FOREACH (bat_seasons_ranked) GENERATE
  SPRINTF("%03d", FLOOR(rank/$chunk_size)) AS chunk_key, player_id..;

-- Writes the chunk key into the file, like it or not.
STORE bat_seasons_chunked INTO '$out_dir/bat_seasons_chunked' 
  USING MultiStorage('$out_dir/bat_seasons_chunked','0'); -- field 0: chunk_key

-- Note that in current versions of Pig, the RANK operator forces parallelism one. If that's unacceptable, we'll quickly sketch a final alternative but send you to the sample code for details. You can instead use RANK on the map side modulo the _number_ of chunks, group on that and store with MultiStorage. This will, however,  have non-uniformity in actual chunk sizes of about the number of map-tasks -- the final lines of each map task are more likely to short-change the higher-numbered chunks. On the upside, the final chunk isn't shorter than the rest (as it is with the prior method or the unix split command).

%DEFAULT n_chunks 8
;

-- no sort key fields, and so it's done on the map side (avoiding the single-reducer drawback of RANK)
bats_ranked_m = FOREACH (RANK bat_seasons) GENERATE
  MOD(rank, $n_chunks) AS chunk_key, player_id..;
bats_chunked_m = FOREACH (GROUP bats_ranked_m BY chunk_key)
  GENERATE FLATTEN(bats_ranked_m);
STORE bats_chunked_m INTO '$out_dir/bats_chunked_m' 
  USING MultiStorage('$out_dir/bat_seasons_chunked','0'); -- field 0: chunk_key
IMPORT 'common_macros.pig'; %DEFAULT data_dir '/data/rawd'; %DEFAULT out_dir '/data/out/baseball';

bat_seasons = load_bat_seasons();
peeps       = load_people();
teams       = load_teams();
park_teams   = load_park_teams();

-- ***************************************************************************
--
-- === Cleaning Up Many Small Files by Merging into Fewer Files

set pig.noSplitCombination     false;
set pig.maxCombinedSplitSize   120100100;

TODO make this use the results of the MultiStorage script

-- mkdir /tmp/events_many ; split -a3 -l 10000 /data/rawd/sports/baseball/events_lite.tsv /tmp/events_many/events-

-- 900+ input files of about 1 MB each; 10 output files of about 120 MB each

events_many = LOAD '/tmp/events_many' AS (
  game_id:chararray, event_seq:int, year_id:int, game_date:chararray, game_seq:int, away_team_id:chararray, home_team_id:chararray, inn:int, inn_home:int, beg_outs_ct:int, away_score:int, home_score:int, event_desc:chararray, event_cd:int, hit_cd:int, ev_outs_ct:int, ev_runs_ct:int, bat_dest:int, run1_dest:int, run2_dest:int, run3_dest:int, is_end_bat:int, is_end_inn:int, is_end_game:int, bat_team_id:chararray, fld_team_id:chararray, pit_id:chararray, bat_id:chararray, run1_id:chararray, run2_id:chararray, run3_id:chararray
  );

STORE_TABLE(events_many, 'events_many');
IMPORT 'common_macros.pig'; %DEFAULT data_dir '/data/rawd'; %DEFAULT out_dir '/data/out/baseball';

bat_seasons = load_bat_seasons();
peeps       = load_people();
teams       = load_teams();
park_teams   = load_park_teams();

-- ***************************************************************************
--
-- === Loading Multiple Files as a Single Table
--

TODO make this target the output of the MultiStorage script instead


-- bat_career = LOAD '/data/rawd/baseball/sports/bat_career AS (...);
-- pit_career = LOAD '/data/rawd/baseball/sports/pit_career AS (...);
bat_names = FOREACH bat_career GENERATE player_id, nameFirst, nameLast;
pit_names = FOREACH pit_career GENERATE player_id, nameFirst, nameLast;
names_in_both = UNION bat_names, pit_names;
player_names = DISTINCT names_in_both;
IMPORT 'common_macros.pig'; %DEFAULT data_dir '/data/rawd'; %DEFAULT out_dir '/data/out/baseball';

bat_seasons       = load_bat_seasons();
peeps       = load_people();
teams       = load_teams();
park_teams   = load_park_teams();

-- ***************************************************************************
--
-- === Treating the Union of Several Tables as a Single Table
--
-- Note that this is not a Join (which requires a reduce, and changes the schema
-- of the records) -- this is more like stacking one table atop another, making
-- no changes to the records (schema or otherwise) and does not require a
-- reduce.

-- A common use of the UNION statement comes in 'symmetrizing' a relationship. For example, each line in the games table describes in a sense two game outcomes: one for the home team and one for the away team. We might reasonably want to prepare another table that listed game _outcomes_: game_id, team, opponent, team's home/away position, team's score, opponent's score. The game between BAL playing at BOS on XXX (final score BOS Y, BAL Z) would get two lines: `GAMEIDXXX BOS BAL 1 Y Z` and `GAMEID BAL BOS 0 Z Y`.

TODO copy over code


-- NOTE: The UNION operator is easy to over-use. For one example, in the next chapter we'll extend the first part of this code to prepare win-loss statistics by team. A plausible first guess would be to follow the UNION statement above with a GROUP statement, but a much better approach would use a COGROUP instead (both operators are explained in the next chapter). The UNION statement is mostly harmless but fairly rare in use; give it a second look any time you find yourself writing it in to a script.
