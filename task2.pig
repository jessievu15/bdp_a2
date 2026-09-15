
-- Load the medals file
medals = load 'hdfs:///medal_table.csv' 
    using PigStorage(',') 
    as (year:int, country_code:chararray, gold:int, silver:int, bronze:int);

-- Filter medeal by year (year,country_code,gold,silver,bronze)
medals_filtered = Filter medals BY year >= 2010 AND year <= 2020;

-- Load the countries file
countries = load 'hdfs:///countries.csv'
    using PigStorage(',') 
    as (country_code:chararray, country_name:chararray, region:chararray);

-- Load the games file
games = load 'hdfs:///games.csv'
    using PigStorage(',') 
    as (year:int, host_city:chararray, host_country_code:chararray);

-- Joins: join using country with Medals with date between 2010 and 2020
-- (2018,USA,9,8,6,USA,United States,North America)
join_medals = JOIN medals_filtered BY country_code, countries BY country_code;

-- Get year, country name, 3 models
-- (2018,United States,9,8,6)
medals_type = FOREACH join_medals GENERATE
    medals_filtered::year AS year,
    countries::country_name AS country_name,
    medals_filtered::gold AS gold,
    medals_filtered::silver AS silver,
    medals_filtered::bronze AS bronze;

-- Join on year 
-- (2018,South Korea,5,8,4,2018,PyeongChang,KOR)
medals_with_host_city = JOIN medals_type BY year, games BY year;


-- Aggregate
-- (2018,South Korea,PyeongChang,5,17)
total_medals_count = FOREACH medals_with_host_city GENERATE
    medals_type::year AS year,
    medals_type::country_name AS country_name,
    games::host_city AS host_city,
    medals_type::gold AS gold,
    (medals_type::gold + medals_type::silver + medals_type::bronze) AS total_medals;

-- Order
total_medals_order = ORDER total_medals_count BY year asc;
gold_counts = FOREACH total_medals_count GENERATE GROUP year;
dump gold_counts;

-- (2014,{(2014,United States,Sochi,9,28)})
-- grouped_by_year = GROUP total_medals_count BY year;
-- dump grouped_by_year;

Register 'task2.py' using org.apache.pig.scripting.jython.JythonScriptEngine as udf;
report = FOREACH  grouped_by_year GENERATE udf.format_Bag(grouped_by_year);
