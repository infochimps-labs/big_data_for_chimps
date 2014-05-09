IMPORT 'common_macros.pig'; %DEFAULT out_dir '/data/out/baseball';
bat_year   = load_bat_seasons();



-- summary    = summarize_field(player_hrs);

table = FOREACH bat_year GENERATE year_id, HR;

summary = FOREACH (GROUP table ALL) {
  dist = DISTINCT table.$1;
  some = LIMIT dist 10; 
  GENERATE
    MIN(table.$1)                       AS min_val,
    MAX(table.$1)                       AS max_val,
    AVG(table.$1)                       AS avg_val,
    SQRT(VAR(table.$1))                 AS stddev_val,
    SUM(table.$1)                       AS sum_val,
    COUNT_STAR(table)                   AS n_recs,
    COUNT_STAR(table) - COUNT(table.$1) AS n_nulls,
    COUNT(dist)                         AS card_val,
    BagToString(some, '|')              AS some_vals
    ;
  };

DUMP summary;


yr_summary = FOREACH (GROUP table BY year_id) {
  dist = DISTINCT table.$1;
  some = LIMIT dist 10; 
  GENERATE
    group                               AS year_id,
    MIN(table.$1)                       AS min_val,
    MAX(table.$1)                       AS max_val,
    AVG(table.$1)                       AS avg_val,
    SQRT(VAR(table.$1))                 AS stddev_val,
    SUM(table.$1)                       AS sum_val,
    COUNT_STAR(table)                   AS n_recs,
    COUNT_STAR(table) - COUNT(table.$1) AS n_nulls,
    COUNT(dist)                         AS card_val,
    BagToString(some, '|')              AS some_vals
    ;
  };

DUMP yr_summary
;
