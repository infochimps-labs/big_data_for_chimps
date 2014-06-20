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
