IMPORT 'common_macros.pig'; %DEFAULT data_dir '/data/rawd'; %DEFAULT out_dir '/data/out/ufos';

sightings = load_sightings();

--
-- ==== Sightings by State
--

sightings_us       = FILTER sightings BY (country == 'United States of America') AND (state != '');
states             = FOREACH sightings_us GENERATE state;
state_sightings_ct = FOREACH (GROUP states BY state) GENERATE
  group, COUNT_STAR(states);

-- To compare against other scripts' output, follow up with
--     cat /tmp/state_sightings_ct_pig/part-r-00000 | sort -k2 > /tmp/state_sightings_ct_pig.tsv


--
-- ==== Sightings by Calendar Month  
--

year_month_ct      = FOREACH sightings GENERATE SUBSTRING(sighted_at, 0, 7) AS yrmo;
sightings_hist     = FOREACH (GROUP year_month_ct BY yrmo) GENERATE
  group, COUNT_STAR(year_month_ct);

-- To compare against other scripts' output, follow up with
--     cat /tmp/state_sightings_ct_pig/part-r-00000 | sort -k2 > /tmp/state_sightings_ct_pig.tsv




-- STORE_TABLE(state_sightings_ct, 'state_sightings_ct');
-- sh cat $out_dir/state_sightings_ct/part\*;

STORE_TABLE(sightings_hist, 'sightings_hist');
sh cat $out_dir/sightings_hist/part\*;
