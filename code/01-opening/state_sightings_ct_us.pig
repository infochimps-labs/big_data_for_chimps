IMPORT '../common_macros.pig'; %DEFAULT out_dir '/tmp';

-- To compare against other scripts' output, follow up with
--     cat /tmp/state_sightings_ct_pig/part-r-00000 | sort -k2 > /tmp/state_sightings_ct_pig.tsv

sightings = LOAD '/Users/flip/ics/core/wukong/data/geo/ufo_sightings/ufo_sightings.tsv'  AS (
  sighted_at: chararray, reported_at: chararray, location_str: chararray,
  shape: chararray, duration_str: chararray, description: chararray,
  lng: float, lat: float,
  city: chararray, county: chararray, state: chararray, country: chararray,
  duration: chararray);

sightings_us       = FILTER sightings BY (country == 'United States of America') AND (state != '');
states             = FOREACH sightings_us GENERATE state;
state_sightings_ct = FOREACH (GROUP states BY state)
  GENERATE COUNT_STAR(states), group;

rmf                            $out_dir/state_sightings_ct_pig;
STORE state_sightings_ct INTO '$out_dir/state_sightings_ct_pig';
