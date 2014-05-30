IMPORT 'common_macros.pig'; %DEFAULT data_dir '/data/rawd'; %DEFAULT out_dir '/data/out/baseball';

bat_seasons       = load_bat_seasons();
peeps       = load_people();
teams       = load_teams();
park_teams   = load_park_teams();

-- ***************************************************************************
--
-- === Treating the Union of Several Tables as a Single Table
--
-- Note that this is not a Join (which requires a reduce, and changes the schema
-- of the records) -- this is more like stacking one table atop another, making
-- no changes to the records (schema or otherwise) and does not require a
-- reduce.

