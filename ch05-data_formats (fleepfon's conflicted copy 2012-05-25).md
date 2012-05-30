# Chapter 5: Data Formats and Schemata

### TSV

As mentioned there's only three data serialization formats you should use: TSV, JSON, or Avro. 

Don't do any quoting -- just escaping

*best practice*

* Restartable - If you have a corrupt record, you only have to look for the next un-escaped newline 
* Keep regexes simple - Quotes and nested parens are hard, 

Don't use CSV -- you're sure to have *some* data with free form text, and then find yourself doing quoting acrobatics or using a different format.

## TSV


## JSON


## Crap

### XML


### Flat format


### Web log

### Others

## Avro Schema

that there is no essential difference among

        File Format         Schema          API             RPC (Remote Procedure Call) Definition
        
        JPG                 CREATE TABLE    Twitter API     Cassandra RPC
        HTML DTD            db defn.
        
Avro says these are imperfect reflections for the same thing: a method to send data in space and time, to yourself or others. This is a very big idea [^1].

### Avro


## ICSS

ICSS uses 


### Schema.org Types




### Munging


    class RawWeatherStation
      field :wban_id
      # ...
      field :latitude
      field :longitude
    end
    
    class Science::Climatology::WeatherStation < Type::Geo::GovernmentBuilding
      field :wban_id
      field :
    end
    
    name:   weatherstation
    types:
      name:   raw_weather_station
      fields:
        - name:  latitude
          type:  float
        - name:  longitude
          type:  float
      # ...
      
### More      

ICSS gives


`_domain_id` and other identifiers




__________________________________________________________________________

[^1] To the people of the future: this might seem totally obvious. Trust that it is not. There are virtually no shared patterns or idioms across the systems listed here.

[^1] Every Avro schema file is a valid ICSS schema file, but Avro will not understand all the fields. In particular, Avro has no notion of 
and ICSS allows 