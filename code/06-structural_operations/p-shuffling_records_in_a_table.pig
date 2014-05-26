IMPORT 'common_macros.pig';

-- Use a hash with good mixing properties to shuffle. MD5 is OK but murmur3 from
-- DATAFU-47 would be even better.
DEFINE HashVal datafu.pig.hash.Hasher('murmur3-32');

vals = LOAD 'us_city_pops.tsv' USING PigStorage('\t', '-tagMetadata')
  AS (metadata:map[], city:chararray, state:chararray, pop:int);

vals_rked     = RANK vals;

DESCRIBE vals_rked;

vals_ided = FOREACH vals_rked GENERATE
  rank_vals,
  metadata,
  metadata#'pathname'  AS pathname:chararray,
  metadata#'sp_index'  AS sp_index:int,
  metadata#'sp_offset' AS sp_offset:long,
  metadata#'sp_bytes'  AS sp_bytes:long,
  city, state, pop;

vals_ided = FOREACH vals_ided GENERATE
  HashVal(pathname) AS pathhash, metadata,
  sp_index, sp_offset, sp_bytes, city, state, pop;

STORE_TABLE('vals_ided',  vals_ided);
-- USING MultiStorage



-- vals_wtag = FOREACH vals_rked {
--   line_info   = CONCAT((chararray)split_info, '#', (chararray)rank_vals);
--   GENERATE HashVal((chararray)line_info) AS rand_id, city, state, pop, FLATTEN(split_attrs) AS (sp_path, sp_idx, sp_offs, sp_size); 
--   };
-- vals_shuffled = FOREACH (ORDER vals_wtag BY rand_id) GENERATE *;
-- STORE vals_shuffled INTO '/data/out/vals_shuffled';
