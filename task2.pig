-- load medal_table.csv for medal tally;
medalTable = LOAD 'hdfs:///medal_table.csv'
             USING PigStorage(',')
             as (year:int, country_code:chararray,
                 gold:int, silver:int,
                 bronze:int);
gmedalTable = group medalTable by year;
-- (year, {year, country_code, gold, silver, bronze});

goldCounts = foreach gmedalTable generate TOP(3, 2, gmedalTable);
             -- as (year, country_code, gold);
-- (year, {year, country_code, gold});
totalCounts = foreach gmedalTable generate group
              as year, country_code,
              (gold + silver + bronze) as gold_count;
-- (year, {year, country_code, gold_count});
-- load countries.csv to get country names;
countries = LOAD 'hdfs:///countries.csv'
            USING PigStorage(',')
            as (country_code:chararray, country_name:chararray,
                country_region:chararray);
joinGoldCname = join goldCounts by country_code, countries by country_code;
-- (country_code, {year, country_code, gold_count, country_code, country_name, country_region});
gGoldbyYear = group joinGoldCname by year;
-- load games.csv for region name;
region = LOAD 'hdfs:///games.csv'
         USING PigStorage(',')
         as (year:int, region_name:chararray, country_code:chararray);
joinGoldRegion = join gGoldbyYear by year, region by year;
-- (year, {year, country_code, gold_count, country_code, country_name, country_region, year, region_name, country_code});
top3gold = foreach joinGoldRegion generate TOP(0, gold_count, joinGoldRegion);
