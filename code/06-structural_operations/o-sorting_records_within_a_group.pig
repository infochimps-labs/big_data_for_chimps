IMPORT 'common_macros.pig'; %DEFAULT data_dir '/data/rawd'; %DEFAULT out_dir '/data/out/baseball';

bats = load_bat_seasons();

-- ***************************************************************************
--
-- === Sorting Records within a Group
