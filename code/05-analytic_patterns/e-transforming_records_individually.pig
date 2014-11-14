IMPORT 'common_macros.pig'; %DEFAULT data_dir '/data/gold'; %DEFAULT out_dir '/data/outd/baseball';

bat_seasons = load_bat_seasons();
people      = load_people();

-- ***************************************************************************
--
-- === Transforming Records Individually
--

-- ==== Concatenating Several Values into a Single String

birthplaces = FOREACH people GENERATE
    player_id,
    CONCAT(birth_city, ', ', birth_state, ', ', birth_country) AS birth_loc
  ;

birthplaces = FOREACH people GENERATE
    player_id,
    CONCAT(birth_city, ', ', birth_state, ', ', birth_country) AS birth_loc,
    CONCAT((chararray)birth_year, '-', (chararray)birth_month, '-', (chararray)birth_day) AS birth_date
  ;

--
-- ==== A nested `FOREACH` Allows Intermediate Expressions
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


--
-- ==== Typecasting a Field
--

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

--
-- ==== Manipulating the Type of a Field
--

rounded = FOREACH bat_seasons GENERATE
  (ROUND(1000.0f*(H + BB + HBP) / PA)) / 1000.0f AS round_and_typecast,
  ((int)(1000.0f*(H + BB + HBP) / PA)) / 1000.0f AS typecast_only,
  (FLOOR(1000.0f*(H + BB + HBP) / PA)) / 1000    AS floor_and_typecast,
  ROUND_TO( 1.0f*(H + BB + HBP) / PA, 3)         AS what_we_would_use,
  1.0f*(H + BB + HBP) / PA                       AS full_value
  ;


--
-- ==== Formatting a String According to a Template
--

formatted = FOREACH bat_seasons GENERATE
  SPRINTF('%4d\t%-9s %-19s\tOBP %5.3f / %-3s %-3s\t%4$012.3e',
    year_id,  player_id,
    CONCAT(name_first, ' ', name_last),
    1.0f*(H + BB + HBP) / PA,
    (year_id >= 1900 ? '.'   : 'pre'),
    (PA >= 450       ? 'sig' : '.')
  ) AS OBP_summary:chararray;


--
-- ==== Assembling Literals with  Complex Type
-- ==== Specifying Schema for Complex Types

-- graphable = FOREACH people
--   {
--   occasions = {
--       ('birth', birth_year, birth_month, birth_day),
--       ('death', death_year, death_month, death_day),
--       ('debut', (int)SUBSTRING(beg_date,0,4), (int)SUBSTRING(beg_date,5,7), (int)SUBSTRING(beg_date,8,10)),
--       ('lastg', (int)SUBSTRING(end_date,0,4), (int)SUBSTRING(end_date,5,7), (int)SUBSTRING(end_date,8,10))
--     };
--   places = (
--     (birth_city, birth_state, birth_country),
--     (death_city, death_state, death_country) );
--   GENERATE
--     player_id,
--     occasions AS occasions:bag{t:(occasion:chararray, year, month, day)},
--     places    AS places:tuple( birth:tuple(city, state, country),
--                                death:tuple(city, state, country) )
--     ;
-- };

date_converted = FOREACH people {
  birth_dt = ToDate(SPRINTF('%s-%s-%sT00:00:00Z', birth_year, Coalesce(birth_month,1), Coalesce(birth_day,1)));
  death_dt = ToDate(SPRINTF('%s-%s-%sT00:00:00Z', death_year, Coalesce(death_month,1), Coalesce(death_day,1)));
  beg_dt   = ToDate(CONCAT(beg_date, 'T00:00:00.000Z'));
  end_dt   = ToDate(end_date, 'yyyy-MM-dd', '+0000');

  GENERATE player_id, birth_dt, death_dt, beg_dt, end_dt,
    -- birth_year, birth_month, birth_day,
    -- (birth_month IS NULL ? 'HIMOM' : ''),
    name_first, name_last;
};

graphable = FOREACH people {
  birth_date = SPRINTF('%s-%s-%s', birth_year, Coalesce(birth_month,1), Coalesce(birth_day,1));
  death_date = SPRINTF('%s-%s-%s', death_year, Coalesce(death_month,1), Coalesce(death_day,1));

  birth_dt = ToDate(SPRINTF('%s-%s-%sT00:00:00Z', birth_year, Coalesce(birth_month,1), Coalesce(birth_day,1)));
  death_dt = ToDate(SPRINTF('%s-%s-%sT00:00:00Z', death_year, Coalesce(death_month,1), Coalesce(death_day,1)));
  beg_dt   = ToDate(CONCAT(beg_date, 'T00:00:00.000Z'));
  end_dt   = ToDate(end_date, 'yyyy-MM-dd', '+0000');

  occasions = {
      ('birth', birth_dt, YearsBetween(birth_dt, birth_dt), birth_city, birth_state, birth_country),
      ('death', death_dt, YearsBetween(death_dt, birth_dt), death_city, death_state, death_country),
      ('debut', beg_dt,     YearsBetween(beg_dt,   birth_dt), (chararray)NULL, (chararray)NULL, (chararray)NULL),
      ('lastg', end_dt,     YearsBetween(end_dt,   birth_dt), (chararray)NULL, (chararray)NULL, (chararray)NULL)
    };

  GENERATE
    player_id,
    occasions AS occasions:bag{t:(
      occasion:chararray, dt:datetime, age:long, city:chararray, state:chararray, country:chararray)}
    -- ,
    -- places    AS places:tuple(
    --   birth:tuple(dt:datetime, city:chararray, state:chararray, country:chararray),
    --   death:tuple(dt:datetime, city:chararray, state:chararray, country:chararray)
    --   -- ,
    --   -- debut:tuple(dt:datetime, city:chararray, state:chararray, country:chararray),
    --   -- final:tuple(dt:datetime, city:chararray, state:chararray, country:chararray)
    -- )
    ;
};

-- => LIMIT obp_1     10; DUMP @; DESCRIBE obp_1  ;
-- => LIMIT obp_2     10; DUMP @; DESCRIBE obp_2  ;
-- => LIMIT obp_3     10; DUMP @; DESCRIBE obp_3  ;
-- => LIMIT obp_4     10; DUMP @; DESCRIBE obp_4  ;
-- => LIMIT broken    10; DUMP @; DESCRIBE broken ;
-- => LIMIT rounded   10; DUMP @; DESCRIBE rounded ;

-- STORE_TABLE(birthplaces, 'birthplaces');
-- STORE_TABLE(core_stats,  'core_stats');

-- STORE_TABLE(date_converted,  'date_converted');
STORE_TABLE(graphable,  'graphable');
-- STORE_TABLE(formatted, 'formatted');

-- From the commandline:
sh egrep '^\\(aaronha01\\|gwynnto02\\|pedrodu01\\|carewro01\\|ansonca01\\|vanlaw01\\|reedeic01\\|willite01\\)\\|HIMOM' /data/outd/baseball/graphable/part\* | wu-lign
-- sh egrep '^\\(aaronha01\\|gwynnto02\\|pedrodu01\\|carewro01\\|ansonca01\\|vanlaw01\\|reedeic01\\|willite01\\)\\|HIMOM' /data/outd/baseball/date_converted/part\* | wu-lign


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



-- ***************************************************************************
--
-- === Working With Strings
--

-- ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
--
-- ==== Splitting a String into Characters
--

-- ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
--
-- ==== Splitting a Delimited String into a Collection of Values
--

-- ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
--
-- ==== Finding a String's Size in Bytes or in Characters
--

-- ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
--
-- ==== Selecting Records that Match a Regular Expression Template
--

-- ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
--
-- ==== Replacing Sections of a String using a Regular Expression
--

-- ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
--
-- ==== Splitting Delimited Data into a Collection of Values
--

-- ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
--
-- ==== Formatting a String With a Template
--
--
