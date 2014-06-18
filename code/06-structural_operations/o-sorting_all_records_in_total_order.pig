IMPORT 'common_macros.pig'; %DEFAULT data_dir '/data/rawd'; %DEFAULT out_dir '/data/out/baseball';

--
-- SET opt.multiquery            false;

-- Run the script 'f-summarizing_multiple_subsets_simultaneously.pig' beforehand
-- to get career stats broken up into young (age 21 and below), prime (22 to 29
-- inclusive), and older (30 and over).
--
career_epochs = LOAD_RESULT('career_epochs');

-- ***************************************************************************
--
-- === Sorting All Records in Total Order

-- We're only going to look at players able to make solid contributions over
-- several years, which we'll define as playing for five or more seasons and
-- 2000 or more plate appearances (enough to show statistical significance), and
-- a OPS of 0.650 (an acceptable-but-not-allstar level) or better.
career_epochs = FILTER career_epochs BY
  ((PA_all >= 2000) AND (n_seasons >= 5) AND (OPS_all >= 0.650));

career_young = ORDER career_epochs BY OPS_young DESC;
career_prime = ORDER career_epochs BY OPS_prime DESC;
career_older = ORDER career_epochs BY OPS_older DESC;

-- You'll spot Ted Williams (willite01) as one of the top three young players,
-- top three prime players, and top three old players. Ted Williams was pretty
-- awesome.
--

-- ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
--
-- ==== Sorting by Multiple Fields
--

-- Sorting on Multiple fields is as easy as adding them in order with commas.
-- Sort by number of older seasons, breaking ties by number of prime seasons:
--
career_older = ORDER career_epochs
  BY n_older DESC, n_prime DESC;

-- Whereever reasonable, "stabilize" your sorts by adding enough columns to make
-- the ordering unique. This ensures the output will remain the same from run to
-- run, a best practice for testing and maintainability.
--
career_older = ORDER career_epochs
  BY n_older DESC, n_prime DESC, player_id ASC; -- makes sure that ties are always broken the same way.

-- ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
--
-- ==== Sorting on an Expression (You Can't)
--

-- Which players have aged the best -- made the biggest leap in performance from
-- their prime years to their older years? You might thing the following would
-- work, but you cannot use an expression in an `ORDER..BY` statement:
--
-- -- by_diff_older = ORDER career_epochs BY (OPS_older-OPS_prime) DESC; -- fails!
--
-- Instead, generate a new field, sort on it, then project it away. Though it's
-- cumbersome to type, there's no significant performance impact.
by_diff_older = FOREACH career_epochs
  GENERATE OPS_older - OPS_prime AS diff, player_id..;
by_diff_older = FOREACH (ORDER by_diff_older BY diff DESC, player_id)
  GENERATE player_id..;

-- If you browse through that table, you'll get a sense that current-era players
-- seem to be over-represented. This is just a simple whiff of a question, but
-- http://j.mp/bd4c-baseball_age_vs_performance[more nuanced analyses] do show
-- an increase in longevity of peak performance.  Part of that is due to better
-- training, nutrition, and medical care -- and part of that is likely due to
-- systemic abuse of performance-enhancing drugs.
--

-- ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
--
-- ==== Sorting Case-insensitive Strings
--

dict        = LOAD '/usr/share/dict/words' AS (word:chararray);

-- There's no intrinsic way to sort case-insensitive; instead, just force a
-- lower-case field to sort with:

sortable    = FOREACH dict GENERATE LOWER(word) AS key, *;
dict_nocase = FOREACH (ORDER sortable BY key DESC, word) GENERATE word;
zzz_nocase  = LIMIT dict_nocase 200;
--
dict_case   = ORDER dict BY word DESC;
zzz_case    = LIMIT dict_case   200;


-- ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
--
-- ==== Dealing with Nulls When Sorting
--

-- When the sort field has nulls, Pig sorts them as least-most by default: they
-- will appear as the first rows for `DESC` order and as the last rows for `ASC`
-- order. To float Nulls to the front or back, project a dummy field having the
-- favoritism you want to impose, and name it first in the `ORDER..BY` clause.
--
nulls_sort_demo = FOREACH career_epochs
  GENERATE (OPS_older IS NULL ? 0 : 1) AS has_older_epoch, player_id..;

nulls_then_vals = FOREACH (ORDER nulls_sort_demo BY
  has_older_epoch ASC,  OPS_all DESC, player_id)
  GENERATE player_id..;

vals_then_nulls = FOREACH (ORDER nulls_sort_demo BY
  has_older_epoch DESC, OPS_all DESC, player_id)
  GENERATE player_id..;

-- ==== Floating Values to the Top or Bottom of the Sort Order
--
-- Use the dummy field trick any time you want to float records to the top or
-- bottom of the sort order based on a criterion. This moves all players whose
-- careers start in 1985 or later to the top, but otherwise sorts on number of
-- older seasons:

post1985_vs_earlier = FOREACH career_epochs
  GENERATE (beg_year >= 1985 ? 1 : 0) AS is_1985, player_id..;
post1985_vs_earlier = FOREACH (ORDER post1985_vs_earlier BY is_1985 DESC, n_older DESC, player_id)
  GENERATE player_id..;

STORE_TABLE(career_young, 'career_young');
STORE_TABLE(career_prime, 'career_prime');
STORE_TABLE(career_older, 'career_older');
--
STORE_TABLE(post1985_vs_earlier, 'post1985_vs_earlier');
STORE_TABLE(nulls_then_vals, 'nulls_then_vals');
STORE_TABLE(vals_then_nulls, 'vals_then_nulls');
--
STORE_TABLE(zzz_nocase, 'zzz_nocase');
STORE_TABLE(zzz_case,   'zzz_case');
