%DEFAULT dsfp_dir '/Users/flip/ics/data_science_fun_pack';
%DEFAULT rawd     '/data/rawd';
%DEFAULT out_dir  '/data/out/baseball';


-- SET pig.verbose                         true;
-- SET pig.exectype                        local;
-- SET pig.logfile                         /tmp/pig-err.log;
-- SET pig.pretty.print.schema             true;

-- SET mapred.compress.map.output          true;
-- SET mapred.map.output.compression.codec org.apache.hadoop.io.compress.SnappyCodec;
-- SET pig.tmpfilecompression              true;
-- SET pig.tmpfilecompression.storage      seqfile
-- SET pig.tmpfilecompression.codec        snappy;
-- SET pig.exec.mapPartAgg                 true;
-- SET pig.noSplitCombination              false;
--

DEFINE STORE_TABLE(filename, table) RETURNS void {
  STORE $table INTO '$out_dir/$filename' USING PigStorage('\t', '--overwrite true');
};


REGISTER           '$dsfp_dir/pig/pig/contrib/piggybank/java/piggybank.jar';
REGISTER           '$dsfp_dir/pig/datafu/datafu-pig/build/libs/datafu-pig-1.2.1.jar';
REGISTER           '$dsfp_dir/pig/pigsy/target/pigsy-2.1.0-SNAPSHOT.jar';

DEFINE Transpose    datafu.pig.util.TransposeTupleToBag();
DEFINE VAR          datafu.pig.stats.VAR();
DEFINE Stitch       org.apache.pig.piggybank.evaluation.Stitch();
DEFINE Over         org.apache.pig.piggybank.evaluation.Over();
DEFINE STRSPLITBAG  pigsy.text.STRSPLITBAG();

-- DEFINE Coalesce            datafu.pig.util.Coalesce();
-- DEFINE NullIfEmpty         datafu.pig.bags.EmptyBagToNullFields();
--
-- DEFINE CountEach           datafu.pig.bags.CountEach();
-- DEFINE BagGroup            datafu.pig.bags.BagGroup();
-- DEFINE BagConcat           datafu.pig.bags.BagConcat();
-- DEFINE AppendToBag         datafu.pig.bags.AppendToBag();
-- DEFINE PrependToBag        datafu.pig.bags.PrependToBag();
-- DEFINE BagLeftOuterJoin    datafu.pig.bags.BagLeftOuterJoin();
--
-- DEFINE VAR                 datafu.pig.stats.VAR();
-- DEFINE SortedMedian        datafu.pig.stats.Median(); -- requires bag be sorted
-- DEFINE ApproxMedian        datafu.pig.stats.StreamingMedian();
-- DEFINE SortedQuartile      datafu.pig.stats.Quantile('0.0','0.25','0.5','0.75','1.0');
-- DEFINE SortedDecile        datafu.pig.stats.Quantile('0.0','0.1','0.2','0.3','0.4','0.5','0.6','0.7','0.8','0.9','1.0');
-- DEFINE ApproxQuartile      datafu.pig.stats.StreamingQuantile('0.0','0.25','0.5','0.75','1.0');
-- DEFINE ApproxDecile        datafu.pig.stats.StreamingQuantile('0.0','0.1','0.2','0.3','0.4','0.5','0.6','0.7','0.8','0.9','1.0');
-- DEFINE ApproxEdgeile       datafu.pig.stats.StreamingQuantile('0.0','0.01','0.05','0.5','0.95','0.99','1.0');
-- DEFINE ApproxCardinality   datafu.pig.stats.HyperLogLogPlusPlus();
--
-- DEFINE MD5                 datafu.pig.hash.MD5();
-- DEFINE MD5base64           datafu.pig.hash.MD5('base64');
-- DEFINE SHA256              datafu.pig.hash.SHA();
-- DEFINE SHA512              datafu.pig.hash.SHA('512');

DEFINE load_allstars() RETURNS loaded {
  $loaded = LOAD '$rawd/sports/baseball/allstars.tsv' AS (
    player_id:chararray, year_id:int,
    game_seq:int, game_id:chararray, team_id:chararray, lg_id:chararray, GP: int, starting_pos:int
    );
};

DEFINE load_bat_seasons() RETURNS loaded {
  $loaded = LOAD '$rawd/sports/baseball/bats_lite.tsv'    AS (
    player_id:chararray, year_id:int, team_id:chararray,
    G:int,     PA:int,    AB:int,    H:int,     BB:int, HBP:int,
    h1B:int,   h2B:int,   h3B:int,   HR:int,    TB:int,
    OBP:float, SLG:float, ISO:float, OPS:float
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
    weight:float,         height:float,
    bats:chararray,       throws:chararray,
    debut:chararray,      finalGame:chararray,
    retro_id:chararray,    bbref_id:chararray
    );
};

DEFINE load_franchises() RETURNS loaded {
  $loaded = LOAD '$rawd/sports/baseball/baseball_databank/csv/TeamsFranchises.csv' USING PigStorage(',') AS (
    franch_id:chararray, franchName:chararray, active:chararray, na_assoc:chararray
    );
};
