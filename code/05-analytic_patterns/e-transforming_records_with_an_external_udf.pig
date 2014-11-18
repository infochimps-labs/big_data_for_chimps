IMPORT 'common_macros.pig'; %DEFAULT data_dir '/data/gold'; %DEFAULT out_dir '/data/outd/baseball';

bat_seasons = load_bat_seasons();
peeps       = load_people();
teams       = load_teams();
park_teams   = load_park_teams();

-- ***************************************************************************
--
-- === Transforming Records with an External UDF
