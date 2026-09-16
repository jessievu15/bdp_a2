-- Load the medals file
medals = load 'medal_table.csv' 
    using PigStorage(',') 
    as (year:int, country_code:chararray, gold:int, silver:int, bronze:int);

-- Filter medal by year (year,country_code,gold,silver,bronze)
medals_filtered = Filter medals BY year >= 2010 AND year <= 2020;

-- Load the countries file
countries = load 'countries.csv'
    using PigStorage(',') 
    as (country_code:chararray, country_name:chararray, region:chararray);

-- Load the games file
games = load 'games.csv'
    using PigStorage(',') 
    as (year:int, host_city:chararray, host_country_code:chararray);

-- Joins: join using country with Medals with date between 2010 and 2020
-- Output=>(2018,USA,9,8,6,USA,United States,North America)
join_medals = JOIN medals_filtered BY country_code, countries BY country_code;

-- Output=>(2018,United States,9,8,6)
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

-- Output=>(2018,South Korea,PyeongChang,17)
total_medals_count = FOREACH medals_with_host_city GENERATE
    medals_type::year AS year,
    medals_type::country_name AS country_name,
    games::host_city AS host_city,
    (medals_type::gold + medals_type::silver + medals_type::bronze) AS total_medals;

-- Output=>(2018,South Korea,PyeongChang,5)
gold_medals_count = FOREACH medals_with_host_city GENERATE
    medals_type::year AS year,
    medals_type::country_name AS country_name,
    games::host_city AS host_city,
    medals_type::gold AS gold;

-- Output=>(2010,{(2010,Italy,Vancouver,5),(2010,Germany,Vancouver,30),(2010,China,Vancouver,11),(2010,Russia / ROC / OAR,Vancouver,15),(2010,United States,Vancouver,37),(2010,Switzerland,Vancouver,9),(2010,Norway,Vancouver,23),(2010,South Korea,Vancouver,14),(2010,Canada,Vancouver,26),(2010,Japan,Vancouver,5),(2010,Sweden,Vancouver,11)})
grouped_total_medals = GROUP total_medals_count BY year;

-- Output=>(2010,{(2010,Italy,Vancouver,1),(2010,Germany,Vancouver,10),(2010,China,Vancouver,5),(2010,Russia / ROC / OAR,Vancouver,3),(2010,United States,Vancouver,9),(2010,Switzerland,Vancouver,6),(2010,Norway,Vancouver,9),(2010,South Korea,Vancouver,6),(2010,Canada,Vancouver,14),(2010,Japan,Vancouver,0),(2010,Sweden,Vancouver,5)})
grouped_gold_medals = GROUP gold_medals_count BY year;

-- Sorting: Get (year, {top-3-tuples}) pair

top3_total_medals = FOREACH grouped_total_medals {
    sorted_total = ORDER total_medals_count BY total_medals DESC;
    top3 = LIMIT sorted_total 3;
    GENERATE group AS year, top3;
};

top3_gold_medals = FOREACH grouped_gold {
    sorted_gold = ORDER gold_count BY gold DESC;
    top3 = LIMIT sorted_gold 3;
    GENERATE group AS year, top3;
};


Register 'task2.py' using org.apache.pig.scripting.jython.JythonScriptEngine as udf;
report = FOREACH  grouped_by_year GENERATE udf.format_Bag(grouped_by_year);
