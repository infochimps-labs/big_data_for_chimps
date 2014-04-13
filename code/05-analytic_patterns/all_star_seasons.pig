IMPORT 'common_macros.pig';
bats    = load_bats();
allstar = load_allstar();

-- Project just what we need
ast       = FOREACH allstar GENERATE playerID, yearID;

-- Cogroup; players without an entry in the ast table will have an empty ast bag
bats_g    = COGROUP ast     BY (playerID, yearID), bats BY (playerID, yearID);
bats_f    = FILTER  bats_g  BY NOT IsEmpty(ast);

-- Project only the batting table fields. One row in the batting table => One row in the result
bats_as   = FOREACH bats_f  GENERATE FLATTEN(bats);

rmf                 /data/out/baseball/bats_as;
STORE bats_as INTO '/data/out/baseball/bats_as';

-- --
-- -- !!! Don't do this with a join !!!
-- --
-- -- From 1959-1962 there were _two_ all-star games, and so the allstar table has multiple entries;
-- -- this means that players will appear twice in the results
-- --
-- 
-- -- This will eliminate the non-allstars... but also produce duplicates!
-- bats_g    = JOIN ast BY (playerID, yearID), bats BY (playerID, yearID);
-- bats_as   = FOREACH bats_g GENERATE bats::playerID .. bats::HR;
-- 
-- rmf                 /data/out/baseball/bats_as_bad;
-- STORE bats_as INTO '/data/out/baseball/bats_as_bad';

