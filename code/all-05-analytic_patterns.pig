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
-- ==== Tokenizing a String into Words
--

-- ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
--
-- ==== Generate a Record for Each Word in a String
--


-- The TOKENIZE command
-- is a fast-and-dirty way to break a string into words
-- (We'll demonstrate a much better tokenizer in the chapter on text data (REF)).
-- The return schema of tokenize is a bag of tuples each holding one word:
-- FLATTEN turns that into one record per word.
--
-- Washington's bad habit of losing franchises makes it the most common token.

tn_toks    = FOREACH franchises
  GENERATE FLATTEN(TOKENIZE(franchName)) AS token;
tn_toks_ct = FOREACH (GROUP tn_toks BY token)
  GENERATE group AS token,
  COUNT(tn_toks.token) AS tok_ct;

team_toks  = ORDER tn_toks_ct BY tok_ct ASC;

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
IMPORT 'common_macros.pig'; %DEFAULT data_dir '/data/rawd'; %DEFAULT out_dir '/data/out/baseball';

bat_seasons = load_bat_seasons();
peeps       = load_people();
teams       = load_teams();
park_teams   = load_park_teams();

-- ***************************************************************************
--
-- === Generating a Sequence Using an Integer Table
IMPORT 'common_macros.pig'; %DEFAULT data_dir '/data/rawd'; %DEFAULT out_dir '/data/out/baseball';

bat_seasons = load_bat_seasons();
peeps       = load_people();
teams       = load_teams();
park_teams   = load_park_teams();

-- ***************************************************************************
--
-- === Transposing Records into Attribute-Value Pairs
IMPORT 'common_macros.pig'; %DEFAULT data_dir '/data/rawd'; %DEFAULT out_dir '/data/out/baseball';

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

typed_strings = FOREACH people {
  fields_bag = {('fn', nameFirst), ('ln', nameLast), ('ct', birthCity), ('ct', deathCity)};
  GENERATE FLATTEN(fields_bag) AS (type:chararray, str:chararray);
  };
-- ('fn',Hank)
-- ('ln',Aaron)
-- ...

typed_chars = FOREACH (FILTER typed_strings BY str != '') {
  chars_bag = STRSPLITBAG(LOWER(str), '(?!^)');
  GENERATE type, FLATTEN(chars_bag) AS token;
  };
DESCRIBE typed_chars;

chars_ct   = FOREACH (GROUP typed_chars BY (type, token))
  GENERATE group.type, group.token, COUNT(typed_chars) AS ct
  ;

chars_freq = FOREACH (GROUP chars_ct BY type) {
  tot_ct = SUM(chars_ct.ct);
  GENERATE group AS type, tot_ct AS tot_ct, FLATTEN(chars_ct.(ct, token));
  };
chars_freq = FOREACH chars_freq GENERATE type, token, ct, (int)ROUND(1e6f*ct/tot_ct) AS freq:int;
DESCRIBE chars_freq;

rmf                    $out_dir/chars_freq;
STORE chars_freq INTO '$out_dir/chars_freq';

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
IMPORT 'common_macros.pig'; %DEFAULT data_dir '/data/rawd'; %DEFAULT out_dir '/data/out/baseball';

bat_seasons = load_bat_seasons();
peeps       = load_people();
teams       = load_teams();
park_teams   = load_park_teams();

-- ***************************************************************************
--
-- === Directing Data Conditionally into Multiple Data Flows
--
IMPORT 'common_macros.pig'; %DEFAULT data_dir '/data/rawd'; %DEFAULT out_dir '/data/out/baseball';

bat_seasons = load_bat_seasons();
peeps       = load_people();
teams       = load_teams();
park_teams   = load_park_teams();

-- ***************************************************************************
--
-- === Partitioning Data into Multiple Files By Key
--
IMPORT 'common_macros.pig'; %DEFAULT data_dir '/data/rawd'; %DEFAULT out_dir '/data/out/baseball';

bat_seasons = load_bat_seasons();
peeps       = load_people();
teams       = load_teams();
park_teams   = load_park_teams();

-- ***************************************************************************
--
-- === Partitioning Data into Uniform Chunks
--
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

