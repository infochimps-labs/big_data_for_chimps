IMPORT 'common_macros.pig'; %DEFAULT data_dir '/data/rawd'; %DEFAULT out_dir '/data/out/baseball';
SET default_parallel 3;

bats = load_bat_seasons();
bats = FILTER bats BY (year_id >= 2000);


-- ***************************************************************************
--
-- === Sorting All Records in Total Order

-- Run the script 'i-summarizing_multiple_subsets_simultaneously.pig' beforehand
-- to get career stats broken up into young (age 21 and below), prime (22 to 29
-- inclusive), and older (30 and over).
--
career_epochs = LOAD_RESULT('career_epochs');

-- We're only going to look at players able to make solid contributions over
-- several years, which we'll define as playing for five or more seasons and
-- 2000 or more plate appearances (enough to show statistical significance), and
-- a OPS of 0.650 (an acceptable-but-not-allstar level) or better.
career_epochs = FILTER career_epochs BY
  ((PA_all >= 2000) AND (n_seasons >= 5) AND (OPS_all >= 0.650));

career_young = ORDER career_epochs BY OPS_young DESC;
career_prime = ORDER career_epochs BY OPS_prime DESC;
career_older = ORDER career_epochs BY OPS_older DESC;

-- STORE_TABLE(career_young, 'career_young');
-- STORE_TABLE(career_prime, 'career_prime');
-- STORE_TABLE(career_older, 'career_older');

-- You'll spot Ted Williams (willite01) as one of the top three young players,
-- top three prime players, and top three old players. He's pretty awesome.
--

-- ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
--
-- ==== Sorting by Multiple Fields
--

-- Sorting on Multiple fields is as easy as adding them in order with commas.
-- Sort by number of older seasons, breaking ties by number of prime seasons:

career_young = ORDER career_epochs BY n_young DESC, n_prime DESC;

-- Whereever reasonable, always "stabilize" your sorts: add a unique id column
-- (or any other you're sure won't have ties), ensuring the output will remain
-- the same from run to run.

career_young = ORDER career_epochs BY n_young DESC, n_prime DESC,
  player_id ASC; -- makes sure that ties are always broken the same way.

-- ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
--
-- ==== Cannot Use an Expression in an ORDER BY statement
--

-- You cannot use an expression to sort the table. This won't work:
--
-- by_diff_older = ORDER career_epochs BY (OPS_older-OPS_prime) DESC; -- fails!


-- Instead, use a foreach to prepare the field and then sort on it:
by_diff_older = ORDER (
  FOREACH career_epochs GENERATE *, OPS_older - OPS_prime AS diff_older
  ) BY diff_older DESC;
STORE_TABLE(by_diff_older, 'by_diff_older');

-- Current-era players seem to be very over-represented at the top of the
-- career_older table. Part of that is due to better training, nutrition, and
-- medical care. Part of that is probably also to to abuse of
-- performance-enhancing drugs.

-- ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
--
-- ==== Dealing with Nulls When Sorting
--

-- When the sort field has nulls you can of course filter them out, and
-- sometimes it's acceptable to substitute in a harmless value using a ternary
-- expression: `(val IS NULL ? 0 : val)`. But you typically want to retain the
-- Null field. By default, Pig will sort Nulls as least-most: the first rows for
-- `BY .. DESC` and the last rows for `BY .. ASC`. You can float Nulls to the
-- front or back by projecting a dummy field exhibiting whatever favoritism
-- you want to impose, and list it first in the sort order.

nulls_sort_demo = FOREACH career_epochs GENERATE
  *, (OPS_older IS NULL ? 0 : 1) AS has_older_epoch;


nulls_then_vals = ORDER nulls_sort_demo BY
  has_older_epoch ASC, OPS_all DESC;

vals_then_nulls = ORDER nulls_sort_demo BY
  has_older_epoch DESC, OPS_all DESC;




-- Floating Values to the Head or Tail of the Sort Order
--
-- Use a dummy field, same as with the preceding discussion on Nulls. This
-- floats to the top all players whose careers start in 1985 or later, and
-- otherwise sorts on number of older seasons:

post1985_vs_earlier = ORDER (
  FOREACH career_epochs GENERATE *, (beg_year >= 1985 ? 1 : 0) AS is_1985
  ) BY is_1985 DESC, n_older DESC;

STORE_TABLE(post1985_vs_earlier, 'post1985_vs_earlier');


-- ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
--
-- ==== Case-insensitive Sorting
--



-- sunset = FOREACH career_epochs GENERATE
--   player_id, beg_year, end_year, OPS_all,
--   (PA_young >= 700 ? OPS_young : Null),
--   (PA_prime >= 700 ? OPS_prime : Null),
--   (PA_older >= 700 ? OPS_older : Null),
--   (PA_young >= 700 AND PA_prime >= 700 ? OPS_young - OPS_prime : Null) AS diff_young,
--   (PA_prime >= 700 AND PA_prime >= 700 ? OPS_prime - OPS_all   : Null) AS diff_prime,
--   (PA_older >= 700 AND PA_prime >= 700 ? OPS_older - OPS_prime : Null) AS diff_older,
--   PA_all, PA_young, PA_prime, PA_older
-- 
--   , ((end_year + beg_year)/2.0 > 1990 ? 'post' : '-') AS epoch
--   ;
-- 
-- golden_oldies = ORDER sunset BY diff_older DESC;


-- If you sort to find older player Those more familiar with the game will also note an overrepresentation of
--
-- http://cms.colgate.edu/portaldata/imagegallerywww/21c0d002-4098-4995-941f-9ae8013632ee/ImageGallery/2012/the-impact-of-age-on-baseball-players-performance.pdf


-- Look at the jobtracker
