-- top_queries = LOAD '/Users/flip/ics/data_science_fun_pack/pig/pig/test/data/pigunit/top_queries_input_data.txt' AS (site:chararray, hits:int);

-- SET;

top_queries = LOAD '/data/rawd/misc/pigunit/top_queries_input_data.txt' AS (site:chararray, hits:int);
  
-- top_queries_g = GROUP top_queries BY site;
-- top_queries_x = FOREACH top_queries_g GENERATE
--   Coalesce(group) AS site, Stitch(top_queries, top_queries) AS tt;
-- DUMP top_queries_x;


round_fiddle = FOREACH top_queries {
  num  = (0.029 * (hits / SIZE(site)));
  GENERATE
    ROUND_TO(num,        4)      AS rnd_dbl,
    ROUND_TO((float)num, 4)      AS rnd_flt,
    ROUND_TO(0.9876543,  5)      AS rnd_bty,
    site, hits, SIZE(site), 
    num
    ;
  };

DESCRIBE round_fiddle;
DUMP round_fiddle;
