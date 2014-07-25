IMPORT 'geo_macros.pig'; %DEFAULT data_dir '/data/rawd'; %DEFAULT out_dir '/data/out/geo';

%DEFAULT zl  9; -- 50-80 km at mid latitudes, about the size of Outer London (M25) or Silicon Valley (San Francisco-San Jose)

airports = load_airports();
gn_pls = load_geonames_places();


-- Map airport coordinates to quad tiles


-- Group on quad key


-- Count and dump



gn_quads = FOREACH gn_pls GENERATE
  quadkey(lng, lat, $zl) AS quadkey, 
  category,
  subcat;

gn_quad_ct = FOREACH (GROUP gn_quads BY quadkey) GENERATE
  quadkey,
  COUNT_STAR(gn_quads)         AS ct_all,
  CountVals(gn_quads.category) AS ct_cats,
  CountVals(gn_quads.subcat)   AS ct_subcats;  

