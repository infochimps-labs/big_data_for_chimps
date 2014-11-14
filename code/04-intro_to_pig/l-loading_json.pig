IMPORT 'common_macros.pig'; %DEFAULT data_dir '/data/gold'; %DEFAULT out_dir '/data/outd/baseball';

bat_seasons = load_bat_seasons();

-- ***************************************************************************
--
-- ==== Storing JSON to disk
--

-- bats_1900_fl = FILTER bat_seasons BY (year_id == 1900);
-- 
-- bats_1900 = FOREACH bats_1900_fl {
--   whatever =   {(HR, R)};
--   GENERATE
--   player_id,
--   year_id,
--   (name_first,name_last) AS full_name:tuple(name_first:chararray,name_last:chararray),
--   team_id, lg_id, age,
--   (G, PA, AB) AS appearances:tuple(G:int, PA:int, AB:int),
--   ['HBP', HBP, 'SH', SH, 'BB', BB, 'H', H] AS hit_stats:map[int],
--   -- : int,h1B: int,h2B: int,h3B: int,HR: int,R: int,RBI: int
--   whatever AS whatever:bag{t:(HR:int, R:int)}
--   ;
-- };
-- 
-- DESCRIBE bats_1900;
-- DUMP bats_1900;

-- rmf                   $out_dir/json_dir_with_schema
-- STORE bats_1900 INTO '$out_dir/json_dir_with_schema'
--   USING org.apache.pig.builtin.JsonStorage();

-- -- ***************************************************************************
-- --
-- -- ==== Loading JSON using a pre-defined schema
-- --

-- bats_with_schema = LOAD '$out_dir/json_dir_with_schema'
--   USING org.apache.pig.builtin.JsonLoader();
-- 


-- ***************************************************************************
--
-- ==== Loading JSON using an in-line schema
--

cp $out_dir/json_dir_with_schema/part-m-00000 $out_dir/json_no_schema.json

bats_no_schema = LOAD '$out_dir/json_no_schema.json'
  USING org.apache.pig.builtin.JsonLoader(
  -- 'player_id: chararray,year_id: int,full_name: (name_first: chararray,name_last: chararray)' --,team_id: chararray,lg_id: chararray,age: int,appearances: (G: int,PA: int,AB: int),hit_stats: map[int],whatever: {t: (HR: int,R: int)}'
  'player_id: chararray,year_id: int,full_name: map[chararray]'
  );

-- DUMP     bats_with_schema;
-- DESCRIBE bats_with_schema;

DUMP     bats_no_schema;
DESCRIBE bats_no_schema;



-- 
-- --
-- -- TODO: ?? to (a) load JSON into a map; or (b) supply a JSON schema see
-- -- https://issues.apache.org/jira/browse/PIG-1914
-- -- 
--
-- -- ***************************************************************************
-- --
-- -- ==== A little script to dump JSON pretty
-- --

-- #!/usr/bin/env ruby
-- 
-- require 'rubygems'
-- ['yajl/json_gem', 'json', 'json/pure'].each do |gem_name|
--   begin
--     require gem_name
--   rescue LoadError ; next ; end
--   break
-- end
-- 
-- $stdin.each do |line|
--   puts JSON.pretty_generate(JSON.load(line))
-- end
