IMPORT 'common_macros.pig'; %DEFAULT data_dir '/data/rawd'; %DEFAULT out_dir '/data/out/baseball';

bat_seasons = load_bat_seasons();
allstars    = load_allstars();

-- ***************************************************************************
--
-- === Selecting Records With No Match in Another Table (anti-join)
--

-- Project just the fields we need
allstars_py  = FOREACH allstars GENERATE player_id, year_id;

-- An outer join of the two will leave both matches and non-matches.
bats_allstars_jn = JOIN
  bat_seasons BY (player_id, year_id) LEFT OUTER,
  allstars_py BY (player_id, year_id);

-- ...and the non-matches will have Nulls in all the allstars slots
bat_seasons_nonast_jn_f = FILTER bats_allstars_jn BY allstars_py::player_id IS NULL;

-- Once the matches have been eliminated, pick off the first table's fields.
-- The double-colon in 'bat_seasons::' makes clear which table's field we mean.
-- The fieldname-ellipsis 'bat_seasons::player_id..bat_seasons::RBI' selects all
-- the fields in bat_seasons from player_id to RBI, which is to say all of them.
bat_seasons_nonast_jn   = FOREACH bat_seasons_nonast_jn_f
  GENERATE bat_seasons::player_id..bat_seasons::RBI;

--
-- This is a good use of the fieldname-ellipsis syntax: to the reader it says
-- "all fields of bat_seasons, the exact members of which are of no concern".
-- (It would be even better if we could write `bat_seasons::*`, but that's not
-- supported in Pig <= 0.12.0.)
--
-- In a context where we did go on to care about the actual fields, that syntax
-- becomes an unstated assumption about not just what fields exist at this
-- stage, but what _order_ they occur in. We can try to justify why you wouldn't
-- use it with a sad story: Suppose you wrote `bat_seasons::PA..bat_seasons::HR`
-- to mean the counting stats (PA, AB, HBP, SH, BB, H, h1B, h2B, h3b, HR). In
-- that case, an upstream rearrangement of the schema could cause fields to be
-- added or removed in a way that would be hard to identify. Now, that failure
-- scenario almost certainly won't happen, and if it did it probably wouldn't
-- lead to real problems, and if there were they most likely wouldn't be that
-- hard to track down. The true point is that it's lazy and unhelpful to the
-- reader. If you mean "PA, AB, HBP, SH, BB, H, h1B, h2B, h3b, HR", then that's
-- what you should say.

-- ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
--
-- An Alternative version: use a COGROUP
--

-- Players with no entry in the allstars_py table have an empty allstars_py bag
bats_ast_cg = COGROUP
  bat_seasons BY (player_id, year_id),
  allstars_py BY (player_id, year_id);

-- Select all cogrouped rows where there were no all-star records, and project
-- the batting table fields.
bat_seasons_nonast_cg = FOREACH
  (FILTER bats_ast_cg BY IsEmpty(allstars_py))
  GENERATE FLATTEN(bat_seasons);

-- -- ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
STORE_TABLE(bat_seasons_nonast_jn, 'bat_seasons_nonast_jn');
STORE_TABLE(bat_seasons_nonast_cg, 'bat_seasons_nonast_cg');


-- -- ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
--
-- There are three opportunities for optimization here. Though these tables are
-- far to small to warrant optimization, it's a good teachable moment for when
-- to (not) optimize.
--
-- * You'll notice that we projected off the extraneous fields from the allstars
--   table before the map. Pig is sometimes smart enough to eliminate fields we
--   don't need early. There's two ways to see if it did so. The surest way is
--   to consult the tree that EXPLAIN produces. If you make the program use
--   `allstars` and not `allstars_py`, you'll see that the extra fields are
--   present. The other way is to look at how much data comes to the reducer
--   with and without the projection. If there is less data using `allstars_py`
--   than `allstars`, the explicit projection is required.
--
-- * The EXPLAIN output also shows that co-group version has a simpler
--   map-reduce plan, raising the question of whether it's more performant.
--
-- * Usually we put the smaller table (allstars) on the right in a join or
--   cogroup. However, although the allstars table is smaller, it has larger
--   cardinality (barely): `(player_id, team_id)` is a primary key for the
--   bat_seasons table. So the order is likely to be irrelevant.
--
EXPLAIN  non_allstars_jn;
EXPLAIN  non_allstars_cg;
--
-- But more performant or possibly more performant doesn't mean "use it
-- instead".
--
-- Eliminating extra fields is almost always worth it, but the explicit
-- projection means extra lines of code and it means an extra alias for the
-- reader to understand. On the other hand, the explicit projection reassures
-- the experienced reader that the projection is for-sure-no-doubt-about-it
-- taking place. That's actually why we chose to be explicit here: we find that
-- the more-complicated script gives the reader less to think about.
--
-- In contrast, any SQL user will immediately recognize the join formulation of
-- this as an anti-join. Introducing a RIGHT OUTER join or choosing the cogroup
-- version disrupts that familiarity. Choose the version you find most readable,
-- and then find out if you care whether it's more performant; the simpler
-- explain graph or the smaller left-hand join table _do not_ necessarily imply
-- a faster dataflow. For this particular shape of data, even at much larger
-- scale we'd be surprised to learn that either of the latter two optimizations
-- mattered.
--
