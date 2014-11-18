IMPORT 'common_macros.pig'; %DEFAULT data_dir '/data/gold'; %DEFAULT out_dir '/data/outd/baseball';

bat_seasons = load_bat_seasons();

-- ***************************************************************************
--
-- === Selecting a Random Sample of Records
--

some_seasons_samp = SAMPLE bat_seasons 0.0625;

--
-- ==== Consistent Sampling of Records by Key, Badly
--

some_seasons_firstchar = FILTER bat_seasons BY (SUBSTRING(player_id, 0, 1) == 's');

--
-- ==== Consistent Sampling of Records by Key Using a Digest
--

-- The seasons for a given player will either all be kept or all be rejected.

DEFINE Hash  datafu.pig.hash.Hasher('murmur3-32');

plhash_seasons = FOREACH bat_seasons GENERATE
  Hash(player_id) AS keep_hash, *;

some_seasons_bypl  = FOREACH (
    FILTER plhash_seasons BY (STARTSWITH(keep_hash, '0'))
  ) GENERATE $0..;

--
-- ==== Consistent Uniform Sampling of Records
--

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

-- ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~

STORE_TABLE(some_seasons_samp,   'some_seasons_samp');
STORE_TABLE(some_seasons_samp,   'some_seasons_firstchar');
STORE_TABLE(some_seasons_bypl,   'some_seasons_bypl');
STORE_TABLE(some_seasons_hash,   'some_seasons_hash');
