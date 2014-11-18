IMPORT 'geo_macros.pig'; %DEFAULT data_dir '/data/gold'; %DEFAULT out_dir '/data/outd/geo';

%DEFAULT zl  8; -- 100 km at 50 deg N lat (top of continental US)

airports = load_airports();
sightings = load_sightings();


--
-- Want to find all airports within 80 km (50 miles) of each sighting
-- 

-- You can't just use a grid cell of 200 km or whatever, because a sighting all the way at the edge won't catch it.
-- We'll use ZL-8
-- 

