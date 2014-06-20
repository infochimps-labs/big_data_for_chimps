IMPORT 'common_macros.pig'; %DEFAULT data_dir '/data/rawd'; %DEFAULT out_dir '/data/out/baseball';

bat_seasons = load_bat_seasons();

-- ***************************************************************************
--
-- === Summarizing Aggregate Statistics of a Full Table
--

--
-- To summarize the statistics of a full table, we use a `GROUP ALL` statement.
-- That is, instead of `GROUP [table] BY [key]`, write `GROUP [table]
-- ALL`. Everything else is as usual:
-- 

weight_summary = FOREACH (GROUP bat_seasons ALL) {
  dist         = DISTINCT bat_seasons.weight;
  sorted_a     = FILTER   bat_seasons.weight BY weight IS NOT NULL;
  sorted       = ORDER    sorted_a BY weight;
  some         = LIMIT    dist.weight 5;
  n_recs       = COUNT_STAR(bat_seasons);
  n_notnulls   = COUNT(bat_seasons.weight);
  GENERATE
    group,
    AVG(bat_seasons.weight)             AS avg_val,
    SQRT(VAR(bat_seasons.weight))       AS stddev_val,
    MIN(bat_seasons.weight)             AS min_val,
    FLATTEN(ApproxEdgeile(sorted))  AS (p01, p05, p50, p95, p99),
    MAX(bat_seasons.weight)             AS max_val,
    --
    n_recs                          AS n_recs,
    n_recs - n_notnulls             AS n_nulls,
    COUNT_STAR(dist)                AS cardinality,
    SUM(bat_seasons.weight)         AS sum_val,
    BagToString(some, '^')          AS some_vals
    ;
};

--
-- As we hope you readily recognize, using the `GROUP ALL` operation can be
-- dangerous, as it requires bringing all the data onto a single reducer.
--
-- We're safe here, even on larger datasets, because all but one of the
-- functions we supplied above are efficiently 'algebraic': they can be
-- significantly performed in the map phase and combiner'ed. This eliminates
-- most of the data before the reducer. The cardinality calculation, done here
-- with a nested DISTINCT operation, is the only real contributor to
-- reducer-side data size. For this dataset its size is manageable, and if it
-- weren't there is a good approximate cardinality function. We'll explain the
-- why and the how of algebraic functions and these approximate methods in the
-- Statistics chapter.  But you'll get a good feel for what is and isn't
-- efficient through the examples in this chapter.)
    
-- NOTE: Note the syntax of the full-table group statement. There's no I in
-- TEAM, and no BY in GROUP ALL.


-- ***************************************************************************
--
-- === Summarizing the Length of a String Field
--

--
-- We showed how to examine the constituents of a string field in the preceding
-- chapter, under "Tokenizing a String" (REF). But for forensic purposes similar
-- to the prior example, it's useful to summarize their length distribution.
-- 

name_first_summary_0 = FOREACH (GROUP bat_seasons ALL) {
  dist       = DISTINCT bat_seasons.name_first;
  lens       = FOREACH  bat_seasons GENERATE SIZE(name_first) AS len;
  --
  n_recs     = COUNT_STAR(bat_seasons);
  n_notnulls = COUNT(bat_seasons.name_first);
  --
  examples   = LIMIT    dist.name_first 5;
  snippets   = FOREACH  examples GENERATE (SIZE(name_first) > 15 ? CONCAT(SUBSTRING(name_first, 0, 15),'…') : name_first) AS val;
  GENERATE
    group,
    'name_first'                   AS var:chararray,
    MIN(lens.len)                  AS minlen,
    MAX(lens.len)                  AS maxlen,
    --
    AVG(lens.len)                  AS avglen,
    SQRT(VAR(lens.len))            AS stdvlen,
    SUM(lens.len)                  AS sumlen,
    --
    n_recs                         AS n_recs,
    n_recs - n_notnulls            AS n_nulls,
    COUNT_STAR(dist)               AS cardinality,
    MIN(bat_seasons.name_first)    AS minval,
    MAX(bat_seasons.name_first)    AS maxval,
    BagToString(snippets, '^')     AS examples,
    lens  AS lens
    ;
};

name_first_summary = FOREACH name_first_summary_0 {
  sortlens   = ORDER lens  BY len;
  pctiles    = ApproxEdgeile(sortlens);
  GENERATE
    var,
    minlen, FLATTEN(pctiles) AS (p01, p05, p10, p50, p90, p95, p99), maxlen,
    avglen, stdvlen, sumlen,
    n_recs, n_nulls, cardinality,
    minval, maxval, examples
    ;
};

DESCRIBE     weight_summary;
STORE_TABLE(weight_summary, 'weight_summary')

DESCRIBE     name_first_summary;
STORE_TABLE(name_first_summary, 'name_first_summary');
