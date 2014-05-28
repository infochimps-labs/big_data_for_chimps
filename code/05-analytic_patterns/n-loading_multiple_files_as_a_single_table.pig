IMPORT 'common_macros.pig'; %DEFAULT data_dir '/data/rawd'; %DEFAULT out_dir '/data/out/baseball';

bat_seasons = load_bat_seasons();
people            = load_people();
teams             = load_teams();
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
