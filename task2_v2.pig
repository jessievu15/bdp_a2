%default START_YEAR 1800
%default END_YEAR 2100

-- Load files
medals = load 'hdfs:///medal_table.csv' 
    using PigStorage(',') 
    as (year:int, country_code:chararray, gold:int, silver:int, bronze:int);

countries = load 'hdfs:///countries.csv'
    using PigStorage(',') 
    as (country_code:chararray, country_name:chararray, region:chararray);

games = load 'hdfs:///games.csv'
    using PigStorage(',') 
    as (year:int, host_city:chararray, host_country_code:chararray);

-- Filter medal by year (year,country_code,gold,silver,bronze)
medals_filtered = Filter medals BY year >= 2010 AND year <= 2020;

-- Joins
join_medals = JOIN medals_filtered BY country_code, countries BY country_code;

medals_type = FOREACH join_medals GENERATE
    medals_filtered::year AS year,
    countries::country_name AS country_name,
    medals_filtered::gold AS gold,
    medals_filtered::silver AS silver,
    medals_filtered::bronze AS bronze;

medals_with_host_city = JOIN medals_type BY year, games BY year;


medals_count = FOREACH medals_with_host_city GENERATE
    medals_type::year AS year,
    medals_type::country_name AS country_name,
    games::host_city AS host_city,
    medals_type::gold AS gold,
    (medals_type::gold + medals_type::silver + medals_type::bronze) AS total_medals;

grouped = GROUP medals_count BY (year, host_city);

REGISTER 'hdfs:///task2.py' USING jython AS task2;
final = FOREACH grouped {
    by_gold  = ORDER medals_count BY gold DESC, country_name ASC;
    top_gold = LIMIT by_gold 3;
    by_total = ORDER medals_count BY total_medals DESC, country_name ASC;
    top_tot  = LIMIT by_total 3;
    gold_count   = FOREACH top_gold GENERATE country_name, gold;
    total_count  = FOREACH top_tot  GENERATE country_name, total_medals;
    GENERATE group.year AS year,
             task2.format_output(group.year, group.host_city, gold_count, total_count) AS final_output;
};

DUMP final;
-- STORE final INTO 'hdfs:///Output/task2' USING PigStorage();
