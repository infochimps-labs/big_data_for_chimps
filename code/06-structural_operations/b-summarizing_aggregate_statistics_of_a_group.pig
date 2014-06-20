IMPORT 'common_macros.pig'; %DEFAULT data_dir '/data/rawd'; %DEFAULT out_dir '/data/out/baseball';

bat_seasons   = load_bat_seasons();

--
-- === Group and Aggregate
--
-- Some of the happiest moments you can have analyzing a massive data set come
-- when you are able to make it a slightly less-massive data set. Statistical
-- aggregations let you summarize the essential characteristics of a table.
--
-- ===== Aggregate Statistics of a Group
--
-- In the previous chapter, we used each player's seasonal counting stats --
-- hits, home runs, and so forth -- to estimate seasonal rate stats -- how well
-- they get on base (OPS), how well they clear the bases (SLG) and an overall
-- estimate of offensive performance (OBP). We can use a group-and-aggregate on
-- the seasonal stats to find each player's career stats.
--
bat_careers = FOREACH (GROUP bat_seasons BY player_id) {
  team_ids = DISTINCT bat_seasons.team_id;
  totG   = SUM(bat_seasons.G);   totPA  = SUM(bat_seasons.PA);  totAB  = SUM(bat_seasons.AB);
  totH   = SUM(bat_seasons.H);   totBB  = SUM(bat_seasons.BB);  totHBP = SUM(bat_seasons.HBP); totR   = SUM(bat_seasons.R);
  toth1B = SUM(bat_seasons.h1B); toth2B = SUM(bat_seasons.h2B); toth3B = SUM(bat_seasons.h3B); totHR  = SUM(bat_seasons.HR);
  OBP    = 1.0*(totH + totBB + totHBP) / totPA;
  SLG    = 1.0*(toth1B + 2*toth2B + 3*toth3B + 4*totHR) / totAB;
  GENERATE
    group                          AS player_id,
    COUNT_STAR(bat_seasons)        AS n_seasons,
    COUNT_STAR(team_ids)           AS n_distinct_teams,
    MIN(bat_seasons.year_id)	     AS beg_year,
    MAX(bat_seasons.year_id)       AS end_year,
    totG   AS G,   totPA  AS PA,  totAB  AS AB,
    totH   AS H,   totBB  AS BB,  totHBP AS HBP,
    toth1B AS h1B, toth2B AS h2B, toth3B AS h3B, totHR AS HR,
    OBP AS OBP, SLG AS SLG, (OBP + SLG) AS OPS
    ;
};

-- We've used some aggregate functions to create an output table with similar structure to the input table, but at a coarser-grained relational level: career rather than season. It's good manners to put the fields in a recognizable order as the original field as we have here. 

DESCRIBE bat_seasons;
DESCRIBE bat_careers;

--
-- ==== Completely Summarizing a Field
-- 

-- The following functions are built in to Pig:
--
-- * Count of all values: `COUNT_STAR(bag)`
-- * Count of non-Null values: `COUNT(bag)`
-- * Cardinality (i.e. the count of distinct values): combine the `DISTINCT` operation and the `COUNT_STAR` function as demonstrated below.
-- * Minimum / Maximum non-Null value: `MIN(bag)` / `MAX(bag)`
-- * Sum of non-Null values: `SUM(bag)`
-- * Average of non-Null values: `AVG(bag)`
--
-- There are a few additional summary functions that aren't native features of
-- Pig, but are offered by Linkedin's might-as-well-be-native DataFu
-- package. footnote:[If you've forgotten/never quite learned what those
-- functions mean, hang on for just a bit and we'll demonstrate them in
-- context. If that still doesn't do it, set a copy of
-- http://www.amazon.com/dp/039334777X[Naked Statistics] or
-- http://www.amazon.com/Head-First-Statistics-Dawn-Griffiths/dp/0596527586[Head
-- First Statistics] next to this book. Both do a good job of efficiently
-- imparting what these functions mean and how to use them without assuming
-- prior expertise or interest in mathematics. This is important material
-- though. Every painter of landscapes must know how to convey the essence of a
-- https://www.youtube.com/watch?v=YLO7tCdBVrA[happy little tree] using a few
-- deft strokes and not the prickly minutae of its 500 branches; the above
-- functions are your brushes footnote:[Artist/Educator Bob Ross: "Anyone can
-- paint, all you need is a dream in your heart and a little bit of practice" --
-- hopefully you're feeling the same way about Big Data analysis.].
--
-- * Variance of non-Null values: `VAR(bag)`, using the `datafu.pig.stats.VAR` UDF
-- * Standard Deviation of non-Null values: `SQRT(VAR(bag))`
-- * Quantiles: `Quantile(bag)` or `StreamingQuantile(bag)`
-- * Median (50th Percentile Value) of a Bag: `Median(bag)` or `StreamingMedian(bag)`
--
-- The previous chapter (REF) has details on how to use UDFs, and so we're going
-- to leave the details of that to the sample code. You'll also notice we list
-- two functions for quantile and for median.  Finding the exact median or other
-- quantiles (as the Median/Quantile UDFs do) is costly at large scale, and so a
-- good approximate algorithm (StreamingMedian/StreamingQuantile) is well
-- appreciated. Since the point of this stanza is to characterize the values for
-- our own sense-making, the approximate algorithms are appropriate. We'll have
-- much more to say about why finding quantiles is costly, why finding averages
-- isn't, and what to do about it in the Statistics chapter (REF).
--

-- weight_summary = FOREACH (GROUP bat_seasons ALL) {
--   dist         = DISTINCT bat_seasons.weight;
--   sorted_a     = FILTER   bat_seasons.weight BY weight IS NOT NULL;
--   sorted       = ORDER    sorted_a BY weight;
--   some         = LIMIT    dist.weight 5;
--   n_recs       = COUNT_STAR(bat_seasons);
--   n_notnulls   = COUNT(bat_seasons.weight);
--   GENERATE
--     group,
--     AVG(bat_seasons.weight)             AS avg_val,
--     SQRT(VAR(bat_seasons.weight))       AS stddev_val,
--     MIN(bat_seasons.weight)             AS min_val,
--     FLATTEN(SortedEdgeile(sorted))  AS (p01, p05, p50, p95, p99),
--     MAX(bat_seasons.weight)             AS max_val,
--     --
--     n_recs                          AS n_recs,
--     n_recs - n_notnulls             AS n_nulls,
--     COUNT_STAR(dist)                     AS cardinality,
--     SUM(bat_seasons.weight)             AS sum_val,
--     BagToString(some, '^')          AS some_vals
--     ;
-- };
--
-- DESCRIBE     weight_summary;
-- STORE_TABLE('weight_summary', weight_summary);
-- cat $out_dir/weight_summary;
--
-- weight_yr_stats = FOREACH (GROUP bat_seasons BY year_id) {
--   dist         = DISTINCT bat_seasons.weight;
--   sorted_a     = FILTER   bat_seasons.weight BY weight IS NOT NULL;
--   sorted       = ORDER    sorted_a BY weight;
--   some         = LIMIT    dist.weight 5;
--   n_recs       = COUNT_STAR(bat_seasons);
--   n_notnulls   = COUNT(bat_seasons.weight);
--   GENERATE
--     group,
--     AVG(bat_seasons.weight)        AS avg_val,
--     SQRT(VAR(bat_seasons.weight))  AS stddev_val,
--     MIN(bat_seasons.weight)        AS min_val,
--     FLATTEN(SortedEdgeile(sorted)) AS (p01, p05, p50, p95, p99),
--     MAX(bat_seasons.weight)        AS max_val,
--     --
--     n_recs                         AS n_recs,
--     n_recs - n_notnulls            AS n_nulls,
--     COUNT_STAR(dist)               AS cardinality,
--     SUM(bat_seasons.weight)        AS sum_val,
--     BagToString(some, '^')         AS some_vals
--     ;
-- };
--
-- DESCRIBE     weight_yr_stats;
-- STORE_TABLE('weight_yr_stats', weight_yr_stats);
-- cat $out_dir/weight_yr_stats;


-- H_summary_base = FOREACH (GROUP bat_seasons ALL) {
--   dist       = DISTINCT bat_seasons.H;
--   examples   = LIMIT    dist.H 5;
--   n_recs     = COUNT_STAR(bat_seasons);
--   n_notnulls = COUNT(bat_seasons.H);
--   GENERATE
--     group,
--     'H'                       AS var:chararray,
--     MIN(bat_seasons.H)             AS minval,
--     MAX(bat_seasons.H)             AS maxval,
--     --
--     AVG(bat_seasons.H)             AS avgval,
--     SQRT(VAR(bat_seasons.H))       AS stddev,
--     SUM(bat_seasons.H)             AS sumval,
--     --
--     n_recs                         AS n_recs,
--     n_recs - n_notnulls            AS n_nulls,
--     COUNT_STAR(dist)               AS cardinality,
--     BagToString(examples, '^')     AS examples
--     ;
-- };
-- -- (all,H,46.838027175098475,56.05447208643693,0,262,77939,0,250,3650509,0^1^2^3^4)
-- 
-- H_summary = FOREACH (GROUP bat_seasons ALL) {
--   dist       = DISTINCT bat_seasons.H;
--   non_nulls  = FILTER   bat_seasons.H BY H IS NOT NULL;
--   sorted     = ORDER    non_nulls BY H;
--   examples   = LIMIT    dist.H 5;
--   n_recs     = COUNT_STAR(bat_seasons);
--   n_notnulls = COUNT(bat_seasons.H);
--   GENERATE
--     group,
--     'H'                       AS var:chararray,
--     MIN(bat_seasons.H)             AS minval,
--     FLATTEN(SortedEdgeile(sorted)) AS (p01, p05, p10, p50, p90, p95, p99),
--     MAX(bat_seasons.H)             AS maxval,
--     --
--     AVG(bat_seasons.H)             AS avgval,
--     SQRT(VAR(bat_seasons.H))       AS stddev,
--     SUM(bat_seasons.H)             AS sumval,
--     --
--     n_recs                         AS n_recs,
--     n_recs - n_notnulls            AS n_nulls,
--     COUNT_STAR(dist)               AS cardinality,
--     BagToString(examples, '^')     AS examples
--     ;
-- };
-- -- (all,H,46.838027175098475,56.05447208643693,0,0.0,0.0,0.0,17.0,141.0,163.0,193.0,262,77939,0,250,3650509,0^1^2^3^4)
-- 
-- -- ***************************************************************************
-- --
-- -- === Completely Summarizing the Values of a String Field
-- --
-- 
-- name_first_summary_0 = FOREACH (GROUP bat_seasons ALL) {
--   dist       = DISTINCT bat_seasons.name_first;
--   lens       = FOREACH  bat_seasons GENERATE SIZE(name_first) AS len; -- Coalesce(name_first,'')
--   --
--   n_recs     = COUNT_STAR(bat_seasons);
--   n_notnulls = COUNT(bat_seasons.name_first);
--   --
--   examples   = LIMIT    dist.name_first 5;
--   snippets   = FOREACH  examples GENERATE (SIZE(name_first) > 15 ? CONCAT(SUBSTRING(name_first, 0, 15),'…') : name_first) AS val;
--   GENERATE
--     group,
--     'name_first'                   AS var:chararray,
--     MIN(lens.len)                  AS minlen,
--     MAX(lens.len)                  AS maxlen,
--     --
--     AVG(lens.len)                  AS avglen,
--     SQRT(VAR(lens.len))            AS stdvlen,
--     SUM(lens.len)                  AS sumlen,
--     --
--     n_recs                         AS n_recs,
--     n_recs - n_notnulls            AS n_nulls,
--     COUNT_STAR(dist)               AS cardinality,
--     MIN(bat_seasons.name_first)    AS minval,
--     MAX(bat_seasons.name_first)    AS maxval,
--     BagToString(snippets, '^')     AS examples,
--     lens  AS lens
--     ;
-- };
-- 
-- name_first_summary = FOREACH name_first_summary_0 {
--   sortlens   = ORDER lens  BY len;
--   pctiles    = SortedEdgeile(sortlens);
--   GENERATE
--     var,
--     minlen, FLATTEN(pctiles) AS (p01, p05, p10, p50, p90, p95, p99), maxlen,
--     avglen, stdvlen, sumlen,
--     n_recs, n_nulls, cardinality,
--     minval, maxval, examples
--     ;
-- };

STORE_TABLE('bat_careers', bat_careers);
