IMPORT 'common_macros.pig'; %DEFAULT data_dir '/data/rawd'; %DEFAULT out_dir '/data/out/baseball';
IMPORT 'summarizer_bot_9000.pig';

bat_seasons = load_bat_seasons();

-- ***************************************************************************
--
-- === Completely Summarizing the Values of a Numeric Field
--

H_summary_base = FOREACH (GROUP bat_seasons ALL) {
  dist       = DISTINCT bat_seasons.H;
  examples   = LIMIT    dist.H 5;
  n_recs     = COUNT_STAR(bat_seasons);
  n_notnulls = COUNT(bat_seasons.H);
  GENERATE
    group,
    'H'                       AS var:chararray,
    MIN(bat_seasons.H)             AS minval,
    MAX(bat_seasons.H)             AS maxval,
    --
    AVG(bat_seasons.H)             AS avgval,
    SQRT(VAR(bat_seasons.H))       AS stddev,
    SUM(bat_seasons.H)             AS sumval,
    --
    n_recs                         AS n_recs,
    n_recs - n_notnulls            AS n_nulls,
    COUNT(dist)                    AS cardinality,
    BagToString(examples, '^')     AS examples
    ;
};
-- (all,H,46.838027175098475,56.05447208643693,0,262,77939,0,250,3650509,0^1^2^3^4)

H_summary = FOREACH (GROUP bat_seasons ALL) {
  dist       = DISTINCT bat_seasons.H;
  non_nulls  = FILTER   bat_seasons.H BY H IS NOT NULL;
  sorted     = ORDER    non_nulls BY H;
  examples   = LIMIT    dist.H 5;
  n_recs     = COUNT_STAR(bat_seasons);
  n_notnulls = COUNT(bat_seasons.H);
  GENERATE
    group,
    'H'                       AS var:chararray,
    MIN(bat_seasons.H)             AS minval,
    FLATTEN(SortedEdgeile(sorted)) AS (p01, p05, p10, p50, p90, p95, p99),
    MAX(bat_seasons.H)             AS maxval,
    --
    AVG(bat_seasons.H)             AS avgval,
    SQRT(VAR(bat_seasons.H))       AS stddev,
    SUM(bat_seasons.H)             AS sumval,
    --
    n_recs                         AS n_recs,
    n_recs - n_notnulls            AS n_nulls,
    COUNT(dist)                    AS cardinality,
    BagToString(examples, '^')     AS examples
    ;
};
-- (all,H,46.838027175098475,56.05447208643693,0,0.0,0.0,0.0,17.0,141.0,163.0,193.0,262,77939,0,250,3650509,0^1^2^3^4)

-- ***************************************************************************
--
-- === Completely Summarizing the Values of a String Field
--

name_first_summary_0 = FOREACH (GROUP bat_seasons ALL) {
  dist       = DISTINCT bat_seasons.name_first;
  lens       = FOREACH  bat_seasons GENERATE SIZE(name_first) AS len; -- Coalesce(name_first,'')
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
    COUNT(dist)                    AS cardinality,
    MIN(bat_seasons.name_first)    AS minval,
    MAX(bat_seasons.name_first)    AS maxval,
    BagToString(snippets, '^')     AS examples,
    lens  AS lens
    ;
};

name_first_summary = FOREACH name_first_summary_0 {
  sortlens   = ORDER lens  BY len;
  pctiles    = SortedEdgeile(sortlens);
  GENERATE
    var,
    minlen, FLATTEN(pctiles) AS (p01, p05, p10, p50, p90, p95, p99), maxlen,
    avglen, stdvlen, sumlen,
    n_recs, n_nulls, cardinality,
    minval, maxval, examples
    ;
};

-- => LIMIT nf_chars 200 ; DUMP @;
-- STORE_TABLE(name_first_summary, 'name_first_summary');
