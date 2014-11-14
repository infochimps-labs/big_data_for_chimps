IMPORT 'common_macros.pig'; %DEFAULT data_dir '/data/gold'; %DEFAULT out_dir '/data/outd/baseball';
IMPORT 'summarizer_bot_9000.pig';

bat_seasons = load_bat_seasons();

-- ***************************************************************************
--
-- === Pig Macros
--

nums_header = numeric_summary_header();
strs_header = strings_summary_header();

-- ***************************************************************************
--
-- === Pig Macros
--

-- (see code in ../common_macros)

-- player_id_summary  = summarize_strings_by(bat_seasons, 'player_id',  'ALL');
-- name_first_summary = summarize_strings_by(bat_seasons, 'name_first', 'ALL');
-- name_last_summary  = summarize_strings_by(bat_seasons, 'name_last',  'ALL');
-- team_id_summary    = summarize_strings_by(bat_seasons, 'team_id',    'ALL');
-- lg_id_summary      = summarize_strings_by(bat_seasons, 'lg_id',      'ALL');
year_id_summary    = summarize_numeric(bat_seasons,   'year_id',    'ALL');
age_summary        = summarize_numeric(bat_seasons,   'age',        'ALL');
G_summary          = summarize_numeric(bat_seasons,   'G',          'ALL');
PA_summary         = summarize_numeric(bat_seasons,   'PA',         'ALL');
AB_summary         = summarize_numeric(bat_seasons,   'AB',         'ALL');
HBP_summary        = summarize_numeric(bat_seasons,   'HBP',        'ALL');
SH_summary         = summarize_numeric(bat_seasons,   'SH',         'ALL');
BB_summary         = summarize_numeric(bat_seasons,   'BB',         'ALL');
H_summary          = summarize_numeric(bat_seasons,   'H',          'ALL');
h1B_summary        = summarize_numeric(bat_seasons,   'h1B',        'ALL');
h2B_summary        = summarize_numeric(bat_seasons,   'h2B',        'ALL');
h3B_summary        = summarize_numeric(bat_seasons,   'h3B',        'ALL');
HR_summary         = summarize_numeric(bat_seasons,   'HR',         'ALL');
R_summary          = summarize_numeric(bat_seasons,   'R',          'ALL');
RBI_summary        = summarize_numeric(bat_seasons,   'RBI',        'ALL');

summaries = UNION
  -- player_id_summary, name_first_summary, name_last_summary,
  -- year_id_summary,   team_id_summary,    lg_id_summary,
  age_summary, G_summary, PA_summary, AB_summary,
  HBP_summary, SH_summary, BB_summary, H_summary,
  h1B_summary, h2B_summary, h3B_summary, HR_summary,
  R_summary, RBI_summary ;

-- STORE_TABLE(player_id_summary,  'player_id_summary' );
-- STORE_TABLE(name_first_summary, 'name_first_summary');
-- STORE_TABLE(name_last_summary,  'name_last_summary' );
-- STORE_TABLE(team_id_summary,    'team_id_summary'   );
-- STORE_TABLE(lg_id_summary,      'lg_id_summary'     );
STORE_TABLE(year_id_summary,    'year_id_summary');
STORE_TABLE(age_summary,        'age_summary'    );
STORE_TABLE(G_summary,          'G_summary'      );
STORE_TABLE(PA_summary,         'PA_summary'     );
STORE_TABLE(AB_summary,         'AB_summary'     );
STORE_TABLE(HBP_summary,        'HBP_summary'    );
STORE_TABLE(SH_summary,         'SH_summary'     );
STORE_TABLE(BB_summary,         'BB_summary'     );
STORE_TABLE(H_summary,          'H_summary'      );
STORE_TABLE(h1B_summary,        'h1B_summary'    );
STORE_TABLE(h2B_summary,        'h2B_summary'    );
STORE_TABLE(h3B_summary,        'h3B_summary'    );
STORE_TABLE(HR_summary,         'HR_summary'     );
STORE_TABLE(R_summary,          'R_summary'      );
STORE_TABLE(RBI_summary,        'RBI_summary'    );

-- STORE_TABLE(summaries, 'summaries');

STORE_TABLE(nums_header, 'nums_header');
STORE_TABLE(strs_header, 'strs_header');

cat $out_dir/strs_header/part-m-00000;
cat $out_dir/nums_header/part-m-00000;
-- cat $out_dir/summaries;

-- ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
--
-- ==== Completely Summarizing the Values of a String Field
--

-- ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
--
-- ==== Finding the Size of a String in Bytes or in Characters
--
-- s.getBytes("UTF-8").length
--

-- ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
--
-- ==== Completely Summarizing the Values of a Numeric Field
--
