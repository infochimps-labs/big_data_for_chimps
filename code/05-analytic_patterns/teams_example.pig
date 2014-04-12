%declare data_dir         '/data/rawd';

teams = LOAD '$data_dir/sports/baseball/baseball_databank/csv/Teams.csv' USING PigStorage(',') AS (
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
teams = FILTER teams BY yearID == 2004 AND lgID == 'AL';

team_opinions = FOREACH teams GENERATE
  teamID,
  case teamID WHEN 'BOS' THEN 'yay' WHEN 'NYA' THEN 'boo' ELSE 'meh' END AS opinion,
  teamname;

DUMP team_opinions;
