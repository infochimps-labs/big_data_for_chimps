-- ***************************************************************************
--
-- Paths and Jars
--
%DEFAULT dsfp_dir '/Users/flip/ics/data_science_fun_pack';

--
-- Versions; must include the leading dash when version is given
--
%DEFAULT datafu_version	   '-1.2.1';
%DEFAULT piggybank_version '';
%DEFAULT pigsy_version	   '-2.1.0-SNAPSHOT';

-- REGISTER           '$dsfp_dir/pig/pig/contrib/piggybank/java/piggybank$piggybank_version.jar';
-- REGISTER           '$dsfp_dir/pig/datafu/datafu-pig/build/libs/datafu-pig$datafu_version.jar';
-- REGISTER           '$dsfp_dir/pig/pigsy/target/pigsy$pigsy_version.jar';

-- ***************************************************************************
--
-- Utility macros
--

DEFINE STORE_TABLE(table, filename) RETURNS void {
  STORE $table INTO '$out_dir/$filename' USING PigStorage('\t'); -- , '--overwrite true -schema');
};

DEFINE LOAD_RESULT(filename) RETURNS loaded {
  $loaded = LOAD '$out_dir/$filename' USING PigStorage('\t'); -- , '-schema');
};

-- ***************************************************************************
--
-- UDFs
--

DEFINE Transpose              datafu.pig.util.TransposeTupleToBag();
DEFINE STRSPLITBAG            pigsy.text.STRSPLITBAG();

DEFINE Coalesce               datafu.pig.util.Coalesce;

DEFINE SortedQuartile         datafu.pig.stats.Quantile('5');
DEFINE ApproxQuartile         datafu.pig.stats.StreamingQuantile('5');
-- DEFINE SortedDecile        datafu.pig.stats.Quantile('10');
-- DEFINE ApproxDecile        datafu.pig.stats.StreamingQuantile('10');
DEFINE SortedEdgeile          datafu.pig.stats.Quantile(          '0.01','0.05', '0.50', '0.95', '0.99');
DEFINE ApproxEdgeile          datafu.pig.stats.StreamingQuantile( '0.01','0.05', '0.50', '0.95', '0.99');
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

-- ***************************************************************************
--
-- Loading Macros
--

DEFINE load_allstars() RETURNS loaded {
  $loaded = LOAD '$data_dir/sports/baseball/allstars.tsv' AS (
    player_id:chararray, year_id:int,
    game_seq:int, game_id:chararray, team_id:chararray, lg_id:chararray, GP: int, starting_pos:int
    );
};

DEFINE load_bat_seasons() RETURNS loaded {
  $loaded = LOAD '$data_dir/sports/baseball/bat_seasons.tsv' USING PigStorage('\t', '--null_string \\N') AS (
    player_id:chararray, name_first:chararray, name_last:chararray,     --  $0- $2
    year_id:int,        team_id:chararray,     lg_id:chararray,         --  $3- $5
    age:int,  G:int,    PA:int,   AB:int,  HBP:int,  SH:int,   BB:int,  --  $6-$12
    H:int,    h1B:int,  h2B:int,  h3B:int, HR:int,   R:int,    RBI:int  -- $13-$19
    );
};

DEFINE load_mod_seasons() RETURNS loaded {
  bat_seasons = load_bat_seasons();
  $loaded = FILTER bat_seasons BY ((year_id >= 1900) AND (lg_id == 'NL' OR lg_id == 'AL'));
};

DEFINE load_sig_seasons() RETURNS loaded {
  bat_seasons = load_bat_seasons();
  $loaded = FILTER bat_seasons BY ((year_id >= 1900) AND (lg_id == 'NL' OR lg_id == 'AL') AND (PA >= 450));
};

DEFINE load_games() RETURNS loaded {
  $loaded = LOAD '$data_dir/sports/baseball/games_lite.tsv' AS (
    game_id:chararray,      year_id:int,
    away_team_id:chararray, home_team_id:chararray,
    away_runs_ct:int,       home_runs_ct:int);
};

DEFINE load_teams() RETURNS loaded {
  $loaded = LOAD '$data_dir/sports/baseball/teams.tsv' USING PigStorage('\t', '--null_string \\N') AS (
    year_id: int, lg_id:chararray, team_id:chararray, franch_id:chararray,          -- 1-4
    div_id:chararray, Rank:int,
    G:int,    Ghome:int, W:int, L:int, DivWin:int, WCWin:int, LgWin:int, WSWin:int, -- 7-14
    R:int,    AB:int,  H:int,   H2B:int, H3B:int,  HR:int,                          -- 15-20
    BB:int,   SO:int,  SB:int,  CS:int,  HBP:int,  SF:int,                          -- 21-26
    RA:int,   ER:int,  ERA:int, CG:int,  SHO:int,  SV:int, IPouts:int, HA:int,      -- 27-34
    HRA:int,  BBA:int, SOA:int, E:int,   DP:int,   FP:int,                          -- 35-40
    team_name:chararray, park_name:chararray, attendance:int,  BPF:int,  PPF:int,   -- 41-45
    team_id_BR:chararray, team_id_lahman45:chararray, team_id_retro:chararray       -- 46-48
    );
};

DEFINE load_park_teams() RETURNS loaded {
  $loaded = LOAD '$data_dir/sports/baseball/park_team_years.tsv' USING PigStorage('\t', '--null_string \\N') AS (
    park_id:chararray, team_id:chararray, year_id:long, beg_date:chararray, end_date:chararray, n_games:long
    );
};

DEFINE load_parks() RETURNS loaded {
  $loaded = LOAD '$data_dir/sports/baseball/park-parts-*.tsv' USING PigStorage('\t', '--null_string \\N') AS (
    park_id:chararray,   park_name:chararray,                                       --  $0..$1
    beg_date:chararray,  end_date:chararray, -- not datetime                        --  $2..$3
    is_active:int,       n_games:long,          lng:double,        lat:double,      --  $4..$7
    city:chararray,      state_id:chararray,    country_id:chararray                --  $8..$10
    );
};

DEFINE load_awards() RETURNS loaded {
  $loaded = LOAD '$data_dir/sports/baseball/awards.tsv' AS (
    award_id:chararray, year_id:long, lg_id:chararray, player_id:chararray, is_winner:int, vote_pct:double, first_pct:double, n_firstv:long, tie:int
    );
};


DEFINE load_hofs() RETURNS loaded {
  $loaded = LOAD '$data_dir/sports/baseball/hof_bat.tsv' AS (
    player_id:chararray, inducted_by:chararray,
    is_inducted:boolean, is_pending:int,
    max_pct:long, n_ballots:long, hof_score:long,
    year_eligible:long, year_inducted:long, pcts:chararray
    );
};


-- see code/models/baseball.rb for schema
DEFINE load_events() RETURNS loaded {
  $loaded = LOAD '$data_dir/sports/baseball/events_lite.tsv' AS (
    game_id:chararray, event_seq:int, year_id:int, game_date:chararray,
    game_seq:int, away_team_id:chararray, home_team_id:chararray, inn:int,
    inn_home:int, beg_outs_ct:int, away_score:int, home_score:int,
    event_desc:chararray, event_cd:int, hit_cd:int, ev_outs_ct:int,
    ev_runs_ct:int, bat_dest:int, run1_dest:int, run2_dest:int, run3_dest:int,
    is_end_bat:int, is_end_inn:int, is_end_game:int, bat_team_id:chararray,
    fld_team_id:chararray, pit_id:chararray, bat_id:chararray,
    run1_id:chararray, run2_id:chararray, run3_id:chararray
    );
};

DEFINE load_some_events(begy, endy) RETURNS loaded {
  evs     = load_events();
  $loaded = FILTER evs BY (year_id >= $begy) AND (year_id <= $endy);
};

DEFINE load_people() RETURNS loaded {
  $loaded = LOAD '$data_dir/sports/baseball/people.tsv' USING PigStorage('\t', '--null_string \\N') AS (
    player_id:chararray,
    birth_year:int,        birth_month:int,       birth_day: int,
    birth_city:chararray,  birth_state:chararray, birth_country: chararray,
    death_year:int,        death_month:int,       death_day: int,
    death_city:chararray,  death_state:chararray, death_country: chararray,
    name_first:chararray,  name_last:chararray,   name_given:chararray,
    height_in:int,         weight_lb:int,
    bats:chararray,        throws:chararray,
    beg_date:chararray,    end_date:chararray,    college:chararray,
    retro_id:chararray,    bbref_id:chararray
    );
};

DEFINE load_franchises() RETURNS loaded {
  $loaded = LOAD '$data_dir/sports/baseball/baseball_databank/csv/TeamsFranchises.csv' USING PigStorage(',') AS (
    franch_id:chararray, franch_name:chararray, active:chararray, na_assoc:chararray
    );
};

DEFINE load_numbers_10k() RETURNS loaded {
  $loaded = LOAD '$data_dir/stats/numbers/numbers-10k.tsv' AS (
    num:int, num0:int, w_null:int, zip:int, uno:int
    );
};

DEFINE load_one_line() RETURNS loaded {
  $loaded = LOAD '$data_dir/stats/numbers/one_line.tsv' AS (uno:int, zilch:int);
};

DEFINE load_us_city_pops() RETURNS loaded {
  $loaded = LOAD '$data_dir/geo/census/us_city_pops.tsv' AS (city:chararray, state:chararray, pop_2011:int);
};

DEFINE load_sightings() RETURNS loaded {
  $loaded = LOAD '/data/gold/geo/ufo_sightings/ufo_sightings.tsv.bz2'  AS (
    sighted_at: chararray,   reported_at: chararray,    location_str: chararray, shape: chararray,
    duration_str: chararray, description: chararray,    lng: float,              lat: float,
    city: chararray,         county: chararray,         state: chararray,        country: chararray );
};

DEFINE load_sightings_dt() RETURNS loaded {
  $loaded = LOAD '/Users/flip/ics/core/wukong/data/geo/ufo_sightings/ufo_sightings.tsv'  AS (
    sighted_at: datetime,    reported_at: datetime,   location_str: chararray, shape: chararray,
    duration_str: chararray, description: chararray,  lng: float,              lat: float,
    city: chararray,         county: chararray,       state: chararray,        country: chararray,
    duration: chararray);
};
