%DEFAULT dsfp_dir '/Users/flip/ics/data_science_fun_pack';
%DEFAULT rawd     '/data/rawd';
%DEFAULT out_dir  '/data/out/baseball';

DEFINE STORE_TABLE(filename, table) RETURNS void {
  STORE $table INTO '$out_dir/$filename' USING PigStorage('\t', '--overwrite true -schema');
};

REGISTER           '$dsfp_dir/pig/pig/contrib/piggybank/java/piggybank.jar';
REGISTER           '$dsfp_dir/pig/datafu/datafu-pig/build/libs/datafu-pig-1.2.1.jar';
REGISTER           '$dsfp_dir/pig/pigsy/target/pigsy-2.1.0-SNAPSHOT.jar';

DEFINE Transpose              datafu.pig.util.TransposeTupleToBag();
DEFINE STRSPLITBAG            pigsy.text.STRSPLITBAG();

DEFINE SortedQuartile         datafu.pig.stats.Quantile('5');
DEFINE ApproxQuartile         datafu.pig.stats.StreamingQuantile('5');
-- DEFINE SortedDecile        datafu.pig.stats.Quantile('10');
-- DEFINE ApproxDecile        datafu.pig.stats.StreamingQuantile('10');
DEFINE SortedEdgeile          datafu.pig.stats.Quantile(          '0.01','0.05', '0.10', '0.50', '0.90', '0.95', '0.99');
DEFINE ApproxEdgeile          datafu.pig.stats.StreamingQuantile( '0.01','0.05', '0.10', '0.50', '0.90', '0.95', '0.99');
-- DEFINE ApproxCardinality   datafu.pig.stats.HyperLogLogPlusPlus();
-- DEFINE SortedMedian        datafu.pig.stats.Median(); -- requires bag be sorted
-- DEFINE ApproxMedian        datafu.pig.stats.StreamingMedian();
--
DEFINE MD5hex                 datafu.pig.hash.MD5('hex');
DEFINE MD5base64              datafu.pig.hash.MD5('base64');
DEFINE MD5                    datafu.pig.hash.MD5('hex');
-- DEFINE SHA256              datafu.pig.hash.SHA();
-- DEFINE SHA512              datafu.pig.hash.SHA('512');
DEFINE CountVals              datafu.pig.bags.CountEach('flatten');

DEFINE summarize_values_by(table, field, keys) RETURNS summary {
  $summary = FOREACH (GROUP $table $keys) {
    dist       = DISTINCT $table.$field;
    non_nulls  = FILTER   $table.$field BY $field IS NOT NULL;
    sorted     = ORDER    non_nulls BY $field;
    some       = LIMIT    dist.$field 5;
    n_recs     = COUNT_STAR($table);
    n_notnulls = COUNT($table.$field);
    GENERATE
      group,
      '$field'                       AS var:chararray,
      AVG($table.$field)             AS avg_val,
      SQRT(VAR($table.$field))       AS stddev_val,
      MIN($table.$field)             AS min_val,
      FLATTEN(SortedEdgeile(sorted)) AS (p01, p05, p10, p50, p90, p95, p99),
      MAX($table.$field)             AS max_val,
      --
      n_recs                         AS n_recs,
      n_recs - n_notnulls            AS n_nulls,
      COUNT(dist)                    AS cardinality,
      SUM($table.$field)             AS sum_val,
      BagToString(some, '^')         AS some_vals
      ;
  };
};

DEFINE summarize_strings_by(table, field, keys) RETURNS summary {
  $summary = FOREACH (GROUP $table $keys) {
    dist       = DISTINCT $table.$field;
    lens       = FOREACH  $table GENERATE SIZE(Coalesce($field,'')) AS len;
    -- sortlens   = ORDER    lens BY len;
    some       = LIMIT    dist.$field 5;
    snippets   = FOREACH  some GENERATE (SIZE($field) > 15 ? CONCAT(SUBSTRING($field, 0, 15),'…') : $field) AS val;
    n_recs     = COUNT_STAR($table);
    n_notnulls = COUNT($table.$field);
    all_chars  = FOREACH dist GENERATE STRSPLITBAG(Coalesce($field,''), '(?!^)');
    chars      = CountVals(BagConcat(all_chars));
    GENERATE
      group,
      '$field'                       AS var:chararray,
      -- AVG(lens.len)                  AS avg_len,
      -- SQRT(VAR(lens.len))            AS stddev_len,
      MIN(lens.len)                  AS min_len,
      -- FLATTEN(SortedEdgeile(sortlens)) AS (p01, p05, p10, p50, p90, p95, p99),
      MAX(lens.len)                  AS max_len,
      --
      n_recs                         AS n_recs,
      n_recs - n_notnulls            AS n_nulls,
      COUNT(dist)                    AS cardinality,
      SUM(lens.len)                  AS sum_len,
      MIN($table.$field)             AS min_val,
      MAX($table.$field)             AS max_val,
      BagToString(snippets, '^')     AS some_vals,
      chars AS chars
      ;
  };
  $summary = FOREACH $summary {
    so_chars = ORDER chars BY count DESC;
    so_chars = LIMIT so_chars 5;
    char_cts = FOREACH so_chars GENERATE CONCAT($0.token, ':', (chararray)count);
    GENERATE var,
      -- avg_len, stddev_len,
      min_len,
      -- p01, p05, p10, p50, p90, p95, p99
      max_len, n_recs, n_nulls, cardinality,
      sum_len, min_val, max_val, some_vals,
      BagToString(char_cts, '|')
      ;
    };
  };

DEFINE load_allstars() RETURNS loaded {
  $loaded = LOAD '$rawd/sports/baseball/allstars.tsv' AS (
    player_id:chararray, year_id:int,
    game_seq:int, game_id:chararray, team_id:chararray, lg_id:chararray, GP: int, starting_pos:int
    );
};

DEFINE load_bat_seasons() RETURNS loaded {
  $loaded = LOAD '$rawd/sports/baseball/bats_lite.tsv'    AS (
    player_id:chararray, year_id:int,
    team_id:chararray,   lg_id:chararray,
    age: int,  G:int,     PA:int,    AB:int,
    HBP:int,   SH: int,   BB:int,    H:int,
    h1B:int,   h2B:int,   h3B:int,   HR:int,
    R:int,     RBI:int,   OBP:float, SLG:float
    );
};

DEFINE load_games() RETURNS loaded {
  $loaded = LOAD '$rawd/sports/baseball/games_lite.tsv' AS (
    game_id:chararray, year_id:int,
    away_team_id:chararray, home_team_id:chararray,
    home_runs_ct:int, away_runs_ct:int);
};

DEFINE load_teams() RETURNS loaded {
  $loaded = LOAD '$rawd/sports/baseball/teams.tsv' AS (
    year_id: int, lg_id:chararray, team_id:chararray, franch_id:chararray,              -- 1-4
    div_id:chararray, Rank:int,
    G:int,    Ghome:int, W:int, L:int, DivWin:int, WCWin:int, LgWin:int, WSWin:int, -- 7-14
    R:int,    AB:int,  H:int,   H2B:int, H3B:int,  HR:int,                          -- 15-20
    BB:int,   SO:int,  SB:int,  CS:int,  HBP:int,  SF:int,                          -- 21-26
    RA:int,   ER:int,  ERA:int, CG:int,  SHO:int,  SV:int, IPouts:int, HA:int,      -- 27-34
    HRA:int,  BBA:int, SOA:int, E:int,   DP:int,   FP:int,                          -- 35-40
    teamname:chararray, park_name:chararray, attendance:int,  BPF:int,  PPF:int,    -- 41-45
    team_id_BR:chararray, team_id_lahman45:chararray, team_id_retro:chararray       -- 46-48
    );
};

DEFINE load_park_tm_yr() RETURNS loaded {
  $loaded = LOAD '$rawd/sports/baseball/park_team_years.tsv' AS (
    park_id:chararray, team_id:chararray, year_id:long, beg_date:chararray, end_date:chararray, n_games:long
    );
};

DEFINE load_parks() RETURNS loaded {
  $loaded = LOAD '$rawd/sports/baseball/parks.tsv' AS (
    park_id:chararray, park_name:chararray,
    -- beg_date:datetime, end_date:datetime,
    beg_date:chararray, end_date:chararray,
    is_active:int, n_games:long, lng:double, lat:double,
    city:chararray, state_id:chararray, country_id:chararray,
    postal_id:chararray, streetaddr:chararray, extaddr:chararray, tel:chararray,
    url:chararray, url_spanish:chararray, logofile:chararray,
    allteams:chararray, allnames:chararray, comments:chararray
    );
};

DEFINE load_awards() RETURNS loaded {
  $loaded = LOAD '$rawd/sports/baseball/awards.tsv' AS (
    award_id:chararray, year_id:long, lg_id:chararray, player_id:chararray, is_winner:int, vote_pct:double, first_pct:double, n_firstv:long, tie:int
    );
};


DEFINE load_hofs() RETURNS loaded {
  $loaded = LOAD '$rawd/sports/baseball/hof_bat.tsv' AS (
    player_id:chararray, inducted_by:chararray,
    is_inducted:boolean, is_pending:int,
    max_pct:long, n_ballots:long, hof_score:long,
    year_eligible:long, year_inducted:long, pcts:chararray
    );
};


-- see sports/baseball/event_lite.rb for schema
DEFINE load_events(begy, endy) RETURNS loaded {
  evs = LOAD '/data/rawd/sports/baseball/events_lite.tsv' AS (
    game_id:chararray, event_seq:int, year_id:int, game_date:chararray, game_seq:int, away_team_id:chararray, home_team_id:chararray, inn:int, inn_home:int, beg_outs_ct:int, away_score:int, home_score:int, event_desc:chararray, event_cd:int, hit_cd:int, ev_outs_ct:int, ev_runs_ct:int, bat_dest:int, run1_dest:int, run2_dest:int, run3_dest:int, is_end_bat:int, is_end_inn:int, is_end_game:int, bat_team_id:chararray, fld_team_id:chararray, pit_id:chararray, bat_id:chararray, run1_id:chararray, run2_id:chararray, run3_id:chararray
    );
  $loaded = FILTER evs BY (year_id >= $begy) AND (year_id <= $endy);
};

DEFINE load_people() RETURNS loaded {
  $loaded = LOAD '$rawd/sports/baseball/baseball_databank/csv/Master.csv' USING PigStorage(',') AS (
    player_id:chararray,
    birthYear:int,        birthMonth:int,       birthDay: int,
    birthCtry: chararray, birthState:chararray, birthCity:chararray,
    deathYear:int,        deathMonth:int,       deathDay: int,
    deathCtry: chararray, deathState:chararray, deathCity:chararray,
    nameFirst:chararray,  nameLast:chararray,   nameGiven:chararray,
    height:int,           weight:int,
    bats:chararray,       throws:chararray,
    debut:chararray,      finalGame:chararray,
    retro_id:chararray,   bbref_id:chararray
    );
};

DEFINE load_franchises() RETURNS loaded {
  $loaded = LOAD '$rawd/sports/baseball/baseball_databank/csv/TeamsFranchises.csv' USING PigStorage(',') AS (
    franch_id:chararray, franch_name:chararray, active:chararray, na_assoc:chararray
    );
};
