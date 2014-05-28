IMPORT 'common_macros.pig'; %DEFAULT data_dir '/data/rawd'; %DEFAULT out_dir '/data/out/baseball';

bat_seasons = load_bat_seasons();
people            = load_people();
teams             = load_teams();
park_teams   = load_park_teams();

-- ***************************************************************************
--
-- ==== Selecting Rows from the Middle of a Result Set
--


