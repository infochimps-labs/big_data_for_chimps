IMPORT 'common_macros.pig'; %DEFAULT data_dir '/data/rawd'; %DEFAULT out_dir '/data/out/baseball';

bat_seasons = load_bat_seasons();

-- ***************************************************************************
--
-- === Transforming Records Individually
--

bat_seasons = LOAD '/tmp/bat_null.tsv' USING PigStorage('\t', '--null_string \\N')   AS (
    player_id:chararray, name_first:chararray, name_last:chararray,     --  $0- $2
    year_id:int,        team_id:chararray,     lg_id:chararray,         --  $3- $5
    age:int,  G:int,    PA:int,   AB:int,  HBP:int,  SH:int,   BB:int,  --  $6-$12
    H:int,    h1B:int,  h2B:int,  h3B:int, HR:int,   R:int,    RBI:int  -- $13-$19
    ) ;

bat_seasons = FILTER bat_seasons BY PA > 0 AND AB > 0;
core_stats  = FOREACH bat_seasons {
  h1B  = H - (h2B + h3B + HR);
  HBP  = (HBP IS NULL ? 0 : HBP);
  TB   = h1B + 2*h2B + 3*h3B + 4*HR;
  OBP  = (H + BB + HBP) / PA;
  SLG  = TB / AB;
  OPS  = SLG + OBP;
  GENERATE
    player_id, name_first, name_last,   --  $0- $2
    year_id,   team_id,   lg_id,        --  $3- $5
    age,  G,   PA,  AB,   HBP, SH,  BB, --  $6-$12
    H,    h1B, h2B, h3B,  HR,  R,  RBI, -- $13-$19
    SLG, OBP, OPS;                      -- $20-$22
};

-- -- ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
-- --
-- 
-- junk_drawer = FOREACH bat_seasons {
--   
--   -- Concatenating Several Values into a Single String
--   full_name  = CONCAT(name_first, ' ', name_last);
--   -- Converting the Lettercase of a String
--   name_shouty = UPPER(name_last);
-- 
--   -- Extracting Characters from a String by Offset
--   initials = CONCAT(
--     SUBSTRING(name_first, 0, 1), '. ',
--     SUBSTRING(name_first, 0, 1), '.');
--   --   The first index in SUBSTRING gives the start, counting from zero.
--   --   The second index gives the _character after the end_.
--   -- Select second through fourth characters with `1, 5`. Makes sense to me!
--   chars234 = SUBSTRING(name_first, 1, 5); 
-- 
--   --   Selecting past the end of a string just takes what's there to take.
--   tail_end     = SUBSTRING(player_id, 6, 99);
--   way_past_end = SUBSTRING(player_id, 69, 99);
-- 
--   -- Handling Special Characters in Strings
--   string_that_will_cause_problems = 'here is a newline:\n'

    
-- ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
--
-- ==== Transforming Nulls into Real Values
--

-- ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
--
-- ==== Working with Null Values
--

-- ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
--
-- ==== Formatting a String According to a Template
--

-- ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
--
-- ==== Replacing Sections of a String using a Regular Expression
--

-- ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
--
-- === A Nested FOREACH Allows Intermediate Expressions


STORE_TABLE(core_stats, 'core_stats');
