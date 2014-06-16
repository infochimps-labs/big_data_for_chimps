
DEFINE summarize_numeric(table, field, keys) RETURNS summary {
  vals     = FOREACH $table GENERATE $0..$15;
  $summary = FOREACH (GROUP vals $keys) {
    sorted     = ORDER      vals   BY $field;
    for_qiles  = FILTER     sorted.$field BY $field IS NOT NULL;
    n_recs     = COUNT_STAR(vals);
    n_notnulls = COUNT(     vals.$field);
    -- some_vals  = LIMIT      vals.$field 10000;
    -- dist       = DISTINCT   some_vals;
    -- examples   = LIMIT      dist 5;
    GENERATE
      group,
      '$field'                       AS field:chararray,
      MIN(vals.$field)             AS minval,
      FLATTEN(SortedEdgeile(for_qiles)) AS (p01, p05, p10, p50, p90, p95, p99),
      MAX(vals.$field)             AS maxval,
      --
      AVG(vals.$field)             AS avgval,
      SQRT(VAR(vals.$field))       AS stddev,
      SUM(vals.$field)             AS sumval,
      --
      n_recs                         AS n_recs,
      n_recs - n_notnulls            AS n_nulls,
      -- COUNT(dist)                    AS cardinality,
      -- BagToString(examples, '^')     AS examples
      1
      ;
  };
};

DEFINE numeric_summary_header() RETURNS header {
  one = LOAD '$data_dir/stats/numbers/one.tsv' AS (num:int);
  $header = FOREACH one GENERATE
    'field',
    'min',    'p01',     'p05',   'p10', 'p50',     'p90',
    'p95',    'p99',     'max',   'avg', 'stddev',  'sum', 
    'n_recs', 'n_nulls', 'cardinality',  'examples';    
};

DEFINE strings_summary_header() RETURNS header {
  one = LOAD '$data_dir/stats/numbers/one.tsv' AS (num:int);
  $header = FOREACH one GENERATE
    'field',
    'minlen', 'p01len', 'p05len', 'p10len', 'p50len', 'p90len', 'p95len', 'p99len', 'maxlen',
    'avglen', 'stdvlen',
    'sumlen',
    'n_recs', 'n_nulls', 'cardinality', 
    'minval', 'maxval',
    'examples';    
};
