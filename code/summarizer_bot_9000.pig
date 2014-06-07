
DEFINE summarize_numeric(table, field, keys) RETURNS summary {
  $summary = FOREACH (GROUP $table $keys) {
    dist       = DISTINCT $table.$field;
    non_nulls  = FILTER   $table.$field BY $field IS NOT NULL;
    sorted     = ORDER    non_nulls BY $field;
    examples   = LIMIT    dist.$field 5;
    n_recs     = COUNT_STAR($table);
    n_notnulls = COUNT($table.$field);
    GENERATE
      group,
      '$field'                       AS var:chararray,
      MIN($table.$field)             AS minval,
      FLATTEN(SortedEdgeile(sorted)) AS (p01, p05, p10, p50, p90, p95, p99),
      MAX($table.$field)             AS maxval,
      --
      AVG($table.$field)             AS avgval,
      SQRT(VAR($table.$field))       AS stddev,
      SUM($table.$field)             AS sumval,
      --
      n_recs                         AS n_recs,
      n_recs - n_notnulls            AS n_nulls,
      COUNT(dist)                    AS cardinality,
      BagToString(examples, '^')     AS examples
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
