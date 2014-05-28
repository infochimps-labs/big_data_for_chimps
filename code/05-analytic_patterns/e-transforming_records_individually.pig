IMPORT 'common_macros.pig'; %DEFAULT data_dir '/data/rawd'; %DEFAULT out_dir '/data/out/baseball';

bat_seasons = load_bat_seasons();

-- ***************************************************************************
--
-- === Transforming Records Individually
--

bat_seasons = FILTER bat_seasons BY PA > 0 AND AB > 0;
core_stats  = FOREACH bat_seasons {
  h1B  = H - (h2B + h3B + HR);
  HBP  = (HBP IS NULL ? 0 : HBP);
  TB   = h1B + 2*h2B + 3*h3B + 4*HR;
  OBP  = (H + BB + HBP) / PA;
  SLG  = TB / AB;
  OPS  = SLG + OBP;
  GENERATE
    player_id, year_id, team_id, lg_id,
    G,   PA,  AB,  HBP, SH,  BB,
    H,   h1B, h2B, h3B, HR,  R,  RBI,
    SLG, OBP, OPS;
};

-- ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
--
-- ==== Concatenating Several Values into a Single String
--

-- ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
--
-- ==== Converting the Lettercase of a String
--

-- ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
--
-- ==== Extracting Characters from a String by Offset
--

-- ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
--
-- ==== Handling Special Characters in Strings
--

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
