-- Adapted from Rena's code
-- Load the medals file
medals = load 'hdfs:///medal_table.csv'
    using PigStorage(',')
    as (year:int, country_code:chararray, gold:int, silver:int, bronze:int);

-- Filter medal by year (year,country_code,gold,silver,bronze)
medals_filtered = Filter medals BY year >= 2010 AND year <= 2020;

-- Load the countries file
countries = load 'hdfs:///countries.csv'
    using PigStorage(',')
    as (country_code:chararray, country_name:chararray, region:chararray);

-- Joins: join using country with Medals with date between 2010 and 2020
-- (2018,USA,9,8,6,USA,United States,North America)
join_medals = JOIN medals_filtered BY country_code, countries BY country_code;

-- Get year, country name, 3 medals
-- (2018,United States,9,8,6)
medals_type = FOREACH join_medals GENERATE
    medals_filtered::year AS year,
    countries::country_code AS country_code,
    countries::country_name AS country_name,
    medals_filtered::gold AS gold,
    medals_filtered::silver AS silver,
    medals_filtered::bronze AS bronze;

-- add host city information
-- Load the games file
games = load 'hdfs:///games.csv'
    using PigStorage(',')
    as (year:int, host_city:chararray, host_country_code:chararray);

-- join games to medals_type
--(2014,CAN,Canada,10,10,5,2014,Sochi,RUS)
-- (2014,RUS,Russia / ROC / OAR,13,11,9,2014,Sochi,RUS)
-- (2018,USA,United States,9,8,6,2018,PyeongChang,KOR)
join_medals_hc = JOIN medals_type BY year, games BY year;

-- Get year, host city, country name, 3 medals
-- (2010,Vancouver,Sweden,5,2,4)
-- (2014,Sochi,Japan,1,4,3)
medals_type_hc = FOREACH join_medals_hc GENERATE
    medals_type::year AS year,
    games::host_city AS host_city,
    medals_type::country_name AS country_name,
    medals_type::gold AS gold,
    medals_type::silver AS silver,
    medals_type::bronze AS bronze;

-- work out top 3 gold medals per year
-- drop the silver and bronze columns
-- (2014,Sochi,Russia / ROC / OAR,13)
-- (2018,PyeongChang,United States,9)
gold_list = FOREACH medals_type_hc GENERATE
    year,
    host_city,
    country_name,
    gold;

-- group gold by year
-- (2010,{(2010,Vancouver,Italy,1),(2010,Vancouver,Germany,10),(2010,Vancouver,China,5),
-- (2010,Vancouver,Russia / ROC / OAR,3),(2010,Vancouver,United States,9),
-- (2010,Vancouver,Switzerland,6),(2010,Vancouver,Norway,9),(2010,Vancouver,South Korea,6),
-- (2010,Vancouver,Canada,14),(2010,Vancouver,Japan,0),(2010,Vancouver,Sweden,5)})
grouped_gold = GROUP gold_list BY year;

-- generate top 3 gold per year
-- (2010,Vancouver,Sweden,5)
-- (2010,Vancouver,Switzerland,6)
-- (2010,Vancouver,United States,9)
-- (2014,Sochi,Sweden,2)
-- (2014,Sochi,Switzerland,6)
-- (2014,Sochi,United States,9)
-- (2018,PyeongChang,Sweden,7)
-- (2018,PyeongChang,United States,9)
-- (2018,PyeongChang,Switzerland,5)
top_3_gold = FOREACH grouped_gold {
    top_bag = TOP(3, 2, gold_list);
    GENERATE FLATTEN(top_bag);
};

-- Order
-- (2010,Vancouver,United States,9)
-- (2010,Vancouver,Switzerland,6)
-- (2010,Vancouver,Sweden,5)
-- (2014,Sochi,United States,9)
-- (2014,Sochi,Switzerland,6)
-- (2014,Sochi,Sweden,2)
-- (2018,PyeongChang,United States,9)
-- (2018,PyeongChang,Sweden,7)
-- (2018,PyeongChang,Switzerland,5)
top_3_gold_sorted = ORDER top_3_gold BY year ASC, gold DESC;

-- work out top total medals per year
-- (2014,Sochi,Japan,1,4,3)
medals_type_hc

-- Aggregate for total medal count
-- (2010,Vancouver,Sweden,11)
-- (2014,Sochi,Japan,8)
total_medals_count = FOREACH medals_type_hc GENERATE
    year,
    host_city,
    country_name,
    (gold + silver + bronze) AS total_medals;

-- group total by year
-- (2010,{(2010,Vancouver,Italy,5),(2010,Vancouver,Germany,30),(2010,Vancouver,China,11),
-- (2010,Vancouver,Russia / ROC / OAR,15),(2010,Vancouver,United States,37),
-- (2010,Vancouver,Switzerland,9),(2010,Vancouver,Norway,23),(2010,Vancouver,South Korea,14),
-- (2010,Vancouver,Canada,26),(2010,Vancouver,Japan,5),(2010,Vancouver,Sweden,11)})
grouped_total = GROUP total_medals_count BY year;

-- generate top total per year
-- (2010,Vancouver,Sweden,11)
-- (2010,Vancouver,Switzerland,9)
-- (2010,Vancouver,United States,37)
-- (2014,Sochi,Sweden,15)
-- (2014,Sochi,Switzerland,11)
-- (2014,Sochi,United States,28)
-- (2018,PyeongChang,Sweden,14)
-- (2018,PyeongChang,United States,23)
-- (2018,PyeongChang,Switzerland,15)

top_3_total_per_year = FOREACH grouped_total {
    top_bag = TOP(3, 2, total_medals_count);
    GENERATE FLATTEN(top_bag);
};

-- Order by year then total count
-- (2010,Vancouver,United States,37)
-- (2010,Vancouver,Sweden,11)
-- (2010,Vancouver,Switzerland,9)
-- (2014,Sochi,United States,28)
-- (2014,Sochi,Sweden,15)
-- (2014,Sochi,Switzerland,11)
-- (2018,PyeongChang,United States,23)
-- (2018,PyeongChang,Switzerland,15)
-- (2018,PyeongChang,Sweden,14)
top_3_total_sorted = ORDER top_3_total_per_year BY year ASC, total_medals DESC;

-- Need to use Rena's Jython
-- Register 'task2.py' using org.apache.pig.scripting.jython.JythonScriptEngine as udf;
-- report = FOREACH  grouped_by_year GENERATE udf.format_Bag(grouped_by_year);


