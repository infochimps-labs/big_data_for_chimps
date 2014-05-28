IMPORT 'common_macros.pig'; %DEFAULT data_dir '/data/rawd'; %DEFAULT out_dir '/data/out/baseball';

bat_seasons = load_bat_seasons();
people            = load_people();
teams             = load_teams();
park_teams   = load_park_teams();

-- ***************************************************************************
--
-- === Selecting Rows that Satisfy a Condition @modern_stats
--

-- Only Modern seasons 
modern_stats = FILTER bat_seasons BY (year_id >= 1900);


-- ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
--
-- ==== Selecting Records that Satisfy Multiple Conditions @modsig_stats
--

-- Modern seasons of more than 450 PA
modsig_stats = FILTER bat_seasons BY 
  (PA >= 450) AND (year_id >= 1900) AND ((lg_id == 'AL') OR (lg_id == 'NL'));


-- ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
--
-- ==== Selecting Records that Match a Regular Expression @funnychars
--

-- Doesn't start with a capital letter, or contains a non-word non-space character
funnychars = FILTER people BY
  (name_last  MATCHES '^([^A-Z]|.*[^\\w\\s]).*') OR 
  (name_first MATCHES '^([^A-Z]|.*[^\\w\\s]).*');


-- ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
--
-- ==== Controlling Case Sensitivity and Other Regular Expression Modifiers  @namesakes
--

-- Name contains a 'Q', 'Flip', or anything in the Philip/Phillip/... family
-- (?i) means "case insensitive"
namesakes = FILTER people BY (name_first MATCHES '(?i).*(q|flip|phil+ip).*');

-- ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
--
-- ==== Selecting Records against a Fixed List of Lookup Values
--

al_east_parks = FILTER park_teams BY
  team_id IN ('BAL', 'BOS', 'CLE', 'DET', 'ML4', 'NYA', 'TBA', 'TOR', 'WS2');


STORE_TABLE(modern_stats,  'modern_stats');
STORE_TABLE(modsig_stats,  'modsig_stats');
STORE_TABLE(funnychars,    'funnychars');
STORE_TABLE(namesakes,     'namesakes');
STORE_TABLE(al_east_parks, 'al_east_parks');


