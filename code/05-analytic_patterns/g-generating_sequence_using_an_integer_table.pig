IMPORT 'common_macros.pig'; %DEFAULT data_dir '/data/rawd'; %DEFAULT out_dir '/data/out/baseball';

bat_seasons = load_bat_seasons();
peeps       = load_people();
teams       = load_teams();
park_teams   = load_park_teams();

-- ***************************************************************************
--
-- === Generating a Sequence Using an Integer Table
--

-- What do you do when there isn't a natural assignment to seed from (eg generating fake data to test with), or when you're trying to enumerate values of a function (every IP address, or the sunrise and sunset times by date, or somesuch)? A table of integers -- yeah, just the lines 1, 2, 3, ... each on subsequent rows -- is astonishingly useful in many circumstances, and this is one of them. This Wukong map-reduce script will generate an arbitrary quantity of fake name, address and credit card data to use for testing purposes.

# seed the RNG with the index

http://www.ruby-doc.org/gems/docs/w/wukong-4.0.0/Wukong/Faker/Helpers.html
Faker::Config.locale = 'en-us'
Faker::Name.name #=> "Tyshawn Johns Sr."
Faker::PhoneNumber.phone_number #=> "397.693.1309"
Faker::Address.street_address #=> "282 Kevin Brook"
Faker::Address.secondary_address #=> "Apt. 672"
Faker::Address.city #=> "Imogeneborough"
Faker::Address.zip_code #=> "58517"
Faker::Address.state_abbr #=> "AP"
Faker::Address.country #=> "French Guiana"
Faker::Business.credit_card_number #=> "1228-1221-1221-1431"
Faker::Business.credit_card_expiry_date #=> <Date: 2015-11-11 ((2457338j,0s,0n),+0s,2299161j)>

mapper do |line|
  idx = line.to_i
  offsets = [ line / C5, (line / C4) % 26, (line / C3) % 26, (line / C2) % 26, line % 26 ]
  chars = offsets.map{|offset| (ORD_A + offset).chr }
  yield chars.join
end


--
-- Generating random values is useful in many circumstances: anonymization, random sampling, test data generation and more. But generating truly random numbers is hard; and as we'll stress several times, it's always best to avoid having mappers that produce different inputs from run to run. An alternative approach is to prepare a giant table of pre-calculated indexed random numbers, and then use a JOIN (see next chapter) to decorate each record with a random value. This may seem hackish on first consideration, but it's the right call in many cases.


-- move to statistics
-- The website random.org makes available a large volume of _true_ randoms number 
-- http://www.random.org/files/

