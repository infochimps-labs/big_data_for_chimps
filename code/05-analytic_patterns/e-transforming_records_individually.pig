IMPORT 'common_macros.pig'; %DEFAULT data_dir '/data/rawd'; %DEFAULT out_dir '/data/out/baseball';

bat_seasons = load_bat_seasons();
people      = load_people();

birthplaces = FOREACH people GENERATE
    player_id,
    CONCAT(birth_city, ', ', birth_state, ', ', birth_country) AS birth_loc
  ;

birthplaces = FOREACH people GENERATE
    player_id,
    CONCAT(birth_city, ', ', birth_state, ', ', birth_country) AS birth_loc,
    CONCAT((chararray)birth_year, '-', (chararray)birth_month, '-', (chararray)birth_day) AS birth_date
  ;


birthplaces = FOREACH people {
  occasions = {
      ('birth', birth_year, birth_month, birth_day),
      ('death', death_year, death_month, death_day),
      ('debut', (int)SUBSTRING(beg_date,0,4), (int)SUBSTRING(beg_date,5,7), (int)SUBSTRING(beg_date,8,10)),
      ('lastg', (int)SUBSTRING(end_date,0,4), (int)SUBSTRING(end_date,5,7), (int)SUBSTRING(end_date,8,10))
    };
  GENERATE
    player_id,
    CONCAT(birth_city, ', ', birth_state, ', ', birth_country) AS birth_loc,
    CONCAT((chararray)birth_year, '-', (chararray)birth_month, '-', (chararray)birth_day) AS birth_date,
    occasions AS occasions:bag{t:(occasion:chararray, year, month, day)}
    ;
};


-- ***************************************************************************
--
-- === Transforming Records Individually
--

bat_seasons = FILTER bat_seasons BY PA > 0 AND AB > 0;
core_stats  = FOREACH bat_seasons {
  TB   = h1B + 2*h2B + 3*h3B + 4*HR;
  OBP  = 1.0f*(H + BB + HBP) / PA;
  SLG  = 1.0f*TB / AB;
  OPS  = SLG + OBP;
  GENERATE
    player_id, name_first, name_last,   --  $0- $2
    year_id,   team_id,   lg_id,        --  $3- $5
    age,  G,   PA,  AB,   HBP, SH,  BB, --  $6-$12
    H,    h1B, h2B, h3B,  HR,  R,  RBI, -- $13-$19
    SLG, OBP, OPS;                      -- $20-$22
};

DESCRIBE core_stats;

obp_1 = FOREACH bat_seasons {
  OBP = 1.0f * (H + BB + HBP) / PA; -- constant is a float
  GENERATE OBP;                     -- making OBP a float
};
obp_2 = FOREACH bat_seasons {
  OBP = 1.0 * (H + BB + HBP) / PA; -- constant is a double (same as if we wrote 1.0)
  GENERATE OBP;                     -- making OBP a double
};
obp_3 = FOREACH bat_seasons {
  OBP = (float)(H + BB + HBP) / PA; -- typecast forces floating-point arithmetic
  GENERATE OBP;                     -- making OBP a float
};
obp_4 = FOREACH bat_seasons {
  OBP = 1.0 * (H + BB + HBP) / PA; -- constant is a double
  GENERATE OBP AS OBP:float;        -- but OBP is explicitly a float
};
broken = FOREACH bat_seasons {
  OBP = (H + BB + HBP) / PA;        -- all int operands means integer math and zero as result
  GENERATE OBP AS OBP:float;        -- even though OBP is explicitly a float
};

rounded = FOREACH bat_seasons GENERATE
  (ROUND(1000.0f*(H + BB + HBP) / PA)) / 1000.0f AS round_and_typecast,
  ((int)(1000.0f*(H + BB + HBP) / PA)) / 1000.0f AS typecast_only,
  (FLOOR(1000.0f*(H + BB + HBP) / PA)) / 1000    AS floor_and_typecast,
  ROUND_TO( 1.0f*(H + BB + HBP) / PA, 3)         AS what_we_would_use,
  1.0f*(H + BB + HBP) / PA                       AS full_value
  ;

formatted = FOREACH bat_seasons GENERATE
  SPRINTF('%4d\t%-9s %-20s\tOBP %5.3f: (%3d + %3d + %2d)/%3d | %4$014.9f',
    year_id,  player_id, CONCAT(name_first, ' ', name_last),
    1.0f*(H + BB + HBP) / PA,
    H, BB, HBP, PA) AS OBP_summary:chararray;


=> LIMIT obp_1     10; DUMP @; DESCRIBE obp_1  ;
=> LIMIT obp_2     10; DUMP @; DESCRIBE obp_2  ;
=> LIMIT obp_3     10; DUMP @; DESCRIBE obp_3  ;
=> LIMIT obp_4     10; DUMP @; DESCRIBE obp_4  ;
=> LIMIT broken    10; DUMP @; DESCRIBE broken ;
=> LIMIT rounded   10; DUMP @; DESCRIBE rounded ;
=> LIMIT formatted 10; DUMP @; DESCRIBE formatted ;

STORE_TABLE(formatted, 'formatted');


-- -- ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
-- --
--
-- junk_drawer = FOREACH one_line {
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


-- ==== Choosing a Value Conditionally

-- demonstrate case and ternary statements (combine/move demonstration in filter section?)

-- ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
--
-- === A Nested FOREACH Allows Intermediate Expressions


-- STORE_TABLE(birthplaces, 'birthplaces');
-- STORE_TABLE(core_stats,  'core_stats');
