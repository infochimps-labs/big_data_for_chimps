IMPORT 'common_macros.pig'; %DEFAULT data_dir '/data/rawd'; %DEFAULT out_dir '/data/out/baseball';

bat_seasons = load_bat_seasons();

-- ***************************************************************************
--
-- === Partitioning Data into Uniform Chunks
--

-- note this should come after the MultiStorage script.

-- An ORDER BY statement with parallelism forced to (output size / desired chunk size) will give you _roughly_ uniform chunks, 

%DEFAULT chunk_size 10000
;

-- Supply enough keys to rank to ensure a stable sorting
bat_seasons_ranked  = RANK bat_seasons BY (player_id, year_id)
bat_seasons_chunked = FOREACH (bat_seasons_ranked) GENERATE
  SPRINTF("%03d", FLOOR(rank/$chunk_size)) AS chunk_key, player_id..;

-- Writes the chunk key into the file, like it or not.
STORE bat_seasons_chunked INTO '$out_dir/bat_seasons_chunked' 
  USING MultiStorage('$out_dir/bat_seasons_chunked','0'); -- field 0: chunk_key

-- Note that in current versions of Pig, the RANK operator forces parallelism one. If that's unacceptable, we'll quickly sketch a final alternative but send you to the sample code for details. You can instead use RANK on the map side modulo the _number_ of chunks, group on that and store with MultiStorage. This will, however,  have non-uniformity in actual chunk sizes of about the number of map-tasks -- the final lines of each map task are more likely to short-change the higher-numbered chunks. On the upside, the final chunk isn't shorter than the rest (as it is with the prior method or the unix split command).

%DEFAULT n_chunks 8
;

-- no sort key fields, and so it's done on the map side (avoiding the single-reducer drawback of RANK)
bats_ranked_m = FOREACH (RANK bat_seasons) GENERATE
  MOD(rank, $n_chunks) AS chunk_key, player_id..;
bats_chunked_m = FOREACH (GROUP bats_ranked_m BY chunk_key)
  GENERATE FLATTEN(bats_ranked_m);
STORE bats_chunked_m INTO '$out_dir/bats_chunked_m' 
  USING MultiStorage('$out_dir/bat_seasons_chunked','0'); -- field 0: chunk_key
