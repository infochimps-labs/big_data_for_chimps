IMPORT 'common_macros.pig'; %DEFAULT data_dir '/data/rawd'; %DEFAULT out_dir '/data/out/baseball';

bat_seasons = load_bat_seasons();
peeps       = load_people();
teams       = load_teams();
park_teams   = load_park_teams();

-- ***************************************************************************
--
-- === Generating Data by Distributing Assignments As Input

-- The best way to generate data in Hadoop is to prepare map inputs that
-- represent assignments of what data to generate. There are two good examples
-- of this pattern elsewhere in the book, so we won't try to contrive one
-- here. One is the "poor-man's data loader" given in Chapter 3 (REF). The
-- mapper input is a list of filenames or database queries; each mapper expands
-- that trivial input into many rows of output. Another is the "self-inflicted
-- DDOS" tool for stress-testing your website (REF). In that case, the mapper
-- input is your historical weblogs, and the mapper output is formed from the
-- web server response.
