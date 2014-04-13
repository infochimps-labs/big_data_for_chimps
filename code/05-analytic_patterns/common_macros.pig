%DEFAULT dsfp_dir '/Users/flip/ics/data_science_fun_pack';
%DEFAULT bdb_dir  '/data/rawd/sports/baseball/baseball_databank/csv';
  
REGISTER           '$dsfp_dir/pig/pig/contrib/piggybank/java/piggybank.jar';
REGISTER           '$dsfp_dir/pig/datafu/dist/datafu-1.2.1-SNAPSHOT.jar';
REGISTER           '$dsfp_dir/pig/pigsy/target/pigsy-2.1.0-SNAPSHOT.jar';

DEFINE Transpose    datafu.pig.util.TransposeTupleToBag();
DEFINE VAR          datafu.pig.stats.VAR();
DEFINE Stitch       org.apache.pig.piggybank.evaluation.Stitch();
DEFINE Over         org.apache.pig.piggybank.evaluation.Over();
DEFINE STRSPLITBAG  pigsy.text.STRSPLITBAG();

DEFINE load_allstar() RETURNS loaded {
  $loaded = LOAD '/tmp/simple_allstar.tsv' AS (
    playerID:chararray, yearID:int,
    gameNum:int, gameID:chararray, teamID:chararray, lgID:chararray, GP: int, startingPos:int
    );
};

DEFINE load_bats() RETURNS loaded {
  $loaded = LOAD '/tmp/simple_bats.tsv'    AS (
    playerID:chararray, yearID:int, teamID:chararray,
    G:int,     PA:int,    AB:int,    H:int,     BB:int, HBP:int,
    h1B:int,   h2B:int,   h3B:int,   HR:int,    TB:int,
    OBP:float, SLG:float, ISO:float, OPS:float
    );
};

DEFINE load_teams() RETURNS loaded {
  $loaded = LOAD '/data/rawd/sports/baseball/baseball_databank/csv/Teams.csv' USING PigStorage(',') AS (
    yearID: int, lgID:chararray, teamID:chararray, franchID:chararray,              -- 1-4
    divID:chararray, Rank:int,
    G:int,    Ghome:int, W:int, L:int, DivWin:int, WCWin:int, LgWin:int, WSWin:int, -- 7-14
    R:int,    AB:int,  H:int,   H2B:int, H3B:int,  HR:int,                          -- 15-20
    BB:int,   SO:int,  SB:int,  CS:int,  HBP:int,  SF:int,                          -- 21-26
    RA:int,   ER:int,  ERA:int, CG:int,  SHO:int,  SV:int, IPouts:int, HA:int,      -- 27-34
    HRA:int,  BBA:int, SOA:int, E:int,   DP:int,   FP:int,                          -- 35-40
    teamname:chararray, park:chararray, attendance:int,  BPF:int,  PPF:int,         -- 41-45
    teamIDBR:chararray, teamIDlahman45:chararray, teamIDretro:chararray             -- 46-48
    );
};

DEFINE load_simple_games() RETURNS loaded {
  $loaded = LOAD '/tmp/games_2004.tsv' AS (
    away_teamID:chararray, home_teamID:chararray, gameID:chararray, yearID:int,
    home_runs_ct:int, away_runs_ct:int);
};

DEFINE load_people() RETURNS loaded {
  $loaded = LOAD '/data/rawd/sports/baseball/baseball_databank/csv/Master.csv' USING PigStorage(',') AS (
    playerID:chararray,
    birthYear:int,        birthMonth:int,       birthDay: int,
    birthCtry: chararray, birthState:chararray, birthCity:chararray,
    deathYear:int,        deathMonth:int,       deathDay: int,
    deathCtry: chararray, deathState:chararray, deathCity:chararray,
    nameFirst:chararray,  nameLast:chararray,   nameGiven:chararray,
    weight:float,         height:float,
    bats:chararray,       throws:chararray,
    debut:chararray,      finalGame:chararray,
    retroID:chararray,    bbrefID:chararray
    );
};

DEFINE load_franchises() RETURNS loaded {
  $loaded = LOAD '/data/rawd/sports/baseball/baseball_databank/csv/TeamsFranchises.csv' USING PigStorage(',') AS (
    franchID:chararray, franchName:chararray, active:chararray, NAassoc:chararray
    );
};
