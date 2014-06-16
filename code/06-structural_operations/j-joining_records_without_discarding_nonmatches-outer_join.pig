IMPORT 'common_macros.pig'; %DEFAULT data_dir '/data/rawd'; %DEFAULT out_dir '/data/out/baseball';

bat_seasons = load_bat_seasons();
peeps       = load_people();
teams       = load_teams();
park_teams   = load_park_tm_yr();

-- ***************************************************************************
--
-- === Joining Records Without Discarding Non-Matches (Outer Join)
--
-- QEM: needs prose (perhaps able to draw from prose file)

-- Here's how to take the career stats table we assembled earlier and decorate it with the years
-- QEM: need to complete sentence/idea



-- One application of an outer join is
-- QEM: need to complete sentence/idea
--
-- Experienced database hands might now suggest doing a join using a SOUNDEX
-- match or some sort of other fuzzy equality. In map-reduce, the only kind of
-- join you can do is on key equality (an "equi-join"). For a sharper example,
-- you cannot do joins on range criteria (where the two keys are related through
-- inequalities (x < y). You can accomplish the _goals_ of a
