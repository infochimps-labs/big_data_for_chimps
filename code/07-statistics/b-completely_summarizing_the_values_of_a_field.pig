IMPORT 'common_macros.pig'; %DEFAULT data_dir '/data/gold'; %DEFAULT out_dir '/data/outd/baseball';
IMPORT 'summarizer_bot_9000.pig';

bat_seasons = load_bat_seasons();


-- stats_G   = summarize_values_by(bat_seasons, 'G',   'ALL');    STORE_TABLE('stats_G',   stats_G  );
-- stats_PA  = summarize_values_by(bat_seasons, 'PA',  'ALL');    STORE_TABLE('stats_PA',  stats_PA  );
-- stats_H   = summarize_values_by(bat_seasons, 'H',   'ALL');    STORE_TABLE('stats_H',   stats_H  );
-- stats_HR  = summarize_values_by(bat_seasons, 'HR',  'ALL');    STORE_TABLE('stats_HR',  stats_HR );
-- stats_OBP = summarize_values_by(bat_seasons, 'OBP', 'ALL');    STORE_TABLE('stats_OBP', stats_OBP);
-- stats_BAV = summarize_values_by(bat_seasons, 'BAV', 'ALL');    STORE_TABLE('stats_BAV', stats_BAV);
-- stats_SLG = summarize_values_by(bat_seasons, 'SLG', 'ALL');    STORE_TABLE('stats_SLG', stats_SLG);
-- stats_OPS = summarize_values_by(bat_seasons, 'OPS', 'ALL');    STORE_TABLE('stats_OPS', stats_OPS);
--
-- stats_wt  = summarize_values_by(bat_seasons, 'weight', 'ALL'); STORE_TABLE('stats_wt', stats_wt);
-- stats_ht  = summarize_values_by(bat_seasons, 'height', 'ALL'); STORE_TABLE('stats_ht', stats_ht);

-- pig ./06-structural_operations/c-summary_statistics.pig
-- cat /data/outd/baseball/stats_*/{.pig_header,part-r-00000} | wu-lign -- %s %s %7.3f %7.3f %7.3f %7.3f %7.3f %7.3f %7.3f %7.3f %7.3f %7.3f %7.3f

-- group   field   average  stdev     min     p01     p05    p50     p95     p99      max  count   nulls   cardnty    sum     examples
-- all     BAV       0.209   0.122   0.000   0.000   0.000   0.231   0.333   0.500   1.000 69127     0     11503       14415  0.0^0.015625^0.01639344262295082^0.01694915254237288^0.017543859649122806
-- all     G        61.575  49.645   1.000   1.000   3.000  43.000 152.000 159.000 165.000 69127     0       165     4256524  1^2^3^4^5
-- all     H        45.956  56.271   0.000   0.000   0.000  15.000 163.000 194.000 262.000 69127     0       250     3176790  0^1^2^3^4
-- all     HR        3.751   7.213   0.000   0.000   0.000   0.000  20.000  34.000  73.000 69127     0        66      259305  0^1^2^3^4
-- all     OBP       0.259   0.134   0.000   0.000   0.000   0.286   0.407   0.556   2.333 69127     0     14214       17872  0.0^0.020833334^0.021276595^0.023255814^0.024390243
-- all     OPS       0.550   0.308   0.000   0.000   0.000   0.602   0.921   1.333   5.000 69127     0     45768       38051  0.0^0.021276595^0.02631579^0.027027028^0.028571429
-- all     PA      197.398 220.678   1.000   1.000   2.000  86.000 643.000 701.000 778.000 69127     0       766    13645539  1^2^3^4^5
-- all     SLG       0.292   0.187   0.000   0.000   0.000   0.312   0.525   0.800   4.000 69127     0     16540       20178  0.0^0.015625^0.016393442^0.01754386^0.018518519
-- all     height  183.700   5.903 160.000 170.000 175.000 183.000 193.000 198.000 211.000 69127   113        21    12677857  null^160^163^165^168
-- all     weight   84.435   8.763  57.000  68.000  73.000  84.000 100.000 109.000 145.000 69127   176        64     5821854  null^57^59^60^61

-- group   field   average  stdev     min     p01     p05    p50     p95     p99      max  count   nulls   cardnty    sum     some
-- all     BAV       0.265   0.036   0.122   0.181   0.207   0.265   0.323   0.353   0.424 27750   0       10841        7352  0.12244897959183673^0.12435233160621761^0.125^0.12598425196850394^0.12878787878787878
-- all     G       114.147  31.707  32.000  46.000  58.000 118.000 156.000 161.000 165.000 27750   0       134       3167587  32^33^34^35^36
-- all     H       103.566  47.301  16.000  28.000  36.000 101.000 182.000 206.000 262.000 27750   0       234       2873945  16^17^18^19^20
-- all     HR        8.829   9.236   0.000   0.000   0.000   6.000  28.000  40.000  73.000 27750   0       66         245001  0^1^2^3^4
-- all     OBP       0.329   0.042   0.156   0.233   0.261   0.328   0.399   0.436   0.609 27750   0       13270        9119  0.15591398^0.16666667^0.16849817^0.16872428^0.16935484
-- all     OPS       0.721   0.115   0.312   0.478   0.544   0.715   0.916   1.027   1.422 27750   0       27642       20014  0.31198335^0.31925547^0.32882884^0.33018503^0.3321846
-- all     PA      430.130 168.812 150.000 154.000 172.000 434.000 682.000 719.000 778.000 27750   0       617      11936098  150^151^152^153^154
-- all     SLG       0.393   0.080   0.148   0.230   0.272   0.387   0.534   0.609   0.863 27750   0       15589       10895  0.14795919^0.15151516^0.15418503^0.15492958^0.15544042
-- all     height  182.460   5.608 163.000 168.000 173.000 183.000 190.000 196.000 203.000 27750   28      17        5058166  null^163^165^168^170
-- all     weight   83.569   8.797  57.000  68.000  71.000  82.000 100.000 109.000 132.000 27750   35      54        2316119  null^57^59^63^64

-- ***************************************************************************
--
-- === Simultaneously Summarizing all Values of a Table
--
-- (move to statistics chapter)

-- The stanza from chapter (REF) to summarize the values of a field is
-- incredibly valuable when feeling out a dataset, and so it would be useful to
-- turn it into a generic script. We will demonstrate the macro expansion
-- feature of Pig by building summarizer_bot-9000, a set of standalone macros
-- you can use to get the full set of summary statistics or histogram for a
-- numeric field, and a summary of the length and composition of a string field.

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
    COUNT_STAR(dist)               AS cardinality,
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
    COUNT_STAR(dist)               AS cardinality,
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
    COUNT_STAR(dist)               AS cardinality,
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
