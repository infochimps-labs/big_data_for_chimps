IMPORT 'common_macros.pig';

people = load_people();
people = LIMIT people 1;

typed_strings = FOREACH people {
  fields_bag = {('fn', nameFirst), ('ln', nameLast), ('ct', birthCity), ('ct', deathCity)};
  GENERATE FLATTEN(fields_bag) AS (type:chararray, str:chararray),
    (deathCity IS NULL ? 'none' : deathCity)
    ;
  };
typed_strings = FILTER typed_strings BY str != '';

-- Output:
-- ('fn',Hank)
-- ('ln',Aaron)
-- ...

typed_chars = FOREACH typed_strings {
  chars_bag = STRSPLITBAG(LOWER(str), '(?!^)');
  GENERATE type, FLATTEN(chars_bag) AS token;
  };
DESCRIBE typed_chars;

chars_g  = GROUP typed_chars BY (type, token);
chars_ct = FOREACH chars_g GENERATE group.type, group.token, COUNT(typed_chars) AS ct;

chars_type_g = GROUP chars_ct BY type;
DESCRIBE chars_type_g;

chars_freq = FOREACH chars_type_g {
  tot = SUM(chars_ct.ct);
  GENERATE group AS type, tot, FLATTEN(chars_ct.(token, ct));
};

DESCRIBE chars_freq;
DUMP     chars_freq;
