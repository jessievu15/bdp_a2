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

-- group by year and host city
-- ((2010,Vancouver),{(2010,Vancouver,Italy,1),(2010,Vancouver,Germany,10),(2010,Vancouver,China,5),
-- (2010,Vancouver,Russia / ROC / OAR,3),(2010,Vancouver,United States,9),(2010,Vancouver,Switzerland,6)
--  (2010,Vancouver,Norway,9),(2010,Vancouver,South Korea,6),(2010,Vancouver,Canada,14),(2010,Vancouver,Japan,0),
-- (2010,Vancouver,Sweden,5)})
grouped_gold = GROUP gold_list BY (year, host_city);

-- Sort by gold descending and country name as tie breaker
-- (2010,Vancouver,Canada,14)
-- (2010,Vancouver,Germany,10)
-- (2010,Vancouver,Norway,9)
-- (2014,Sochi,Russia / ROC / OAR,13)
-- (2014,Sochi,Norway,11)
-- (2014,Sochi,Canada,10)
-- (2018,PyeongChang,Germany,14)
-- (2018,PyeongChang,Norway,14)
-- (2018,PyeongChang,Canada,11)
top_3_gold = FOREACH grouped_gold {
    sorted_bag = ORDER gold_list BY gold DESC, country_name ASC;
    top_bag = LIMIT sorted_bag 3;
    GENERATE FLATTEN (top_bag) AS (year, host_city, country_name, gold);
};

-- group top 3 gold by year and host city
-- ((2010,Vancouver),{(2010,Vancouver,Norway,9),(2010,Vancouver,Germany,10),(2010,Vancouver,Canada,14)})
   --((2014,Sochi),{(2014,Sochi,Canada,10),(2014,Sochi,Norway,11),(2014,Sochi,Russia / ROC / OAR,13)})
   --((2018,PyeongChang),{(2018,PyeongChang,Canada,11),(2018,PyeongChang,Norway,14),(2018,PyeongChang,Germany,14)})
group_top_3_gold = GROUP top_3_gold BY (year, host_city);

-- work out top total medals per year
-- Aggregate for total medal count
-- (2010,Vancouver,Sweden,11)
-- (2014,Sochi,Japan,8)
total_list = FOREACH medals_type_hc GENERATE
    year,
    host_city,
    country_name,
    (gold + silver + bronze) AS total;

-- group by year and host city
grouped_total = GROUP total_list BY (year, host_city);

-- Sort by gold descending and country name as tie breaker
-- (2010,Vancouver,United States,37)
-- (2010,Vancouver,Germany,30)
-- (2010,Vancouver,Canada,26)
-- (2014,Sochi,Russia / ROC / OAR,33)
-- (2014,Sochi,United States,28)
-- (2014,Sochi,Norway,26)
-- (2018,PyeongChang,Norway,39)
-- (2018,PyeongChang,Germany,31)
-- (2018,PyeongChang,Canada,29)
top_3_total = FOREACH grouped_total {
    sorted_bag = ORDER total_list BY total DESC, country_name ASC;
    top_bag = LIMIT sorted_bag 3;
    GENERATE FLATTEN (top_bag) AS (year, host_city, country_name, total);
};

-- group top 3 total by year and host city
-- ((2010,Vancouver),{(2010,Vancouver,Canada,26),(2010,Vancouver,Germany,30),(2010,Vancouver,United States,37)})
   --((2014,Sochi),{(2014,Sochi,Norway,26),(2014,Sochi,United States,28),(2014,Sochi,Russia / ROC / OAR,33)})
   --((2018,PyeongChang),{(2018,PyeongChang,Canada,29),(2018,PyeongChang,Germany,31),(2018,PyeongChang,Norway,39)})
group_top_3_total = GROUP top_3_total BY (year, host_city);

-- join the two bags
-- ((2010,Vancouver),{(2010,Vancouver,Norway,9),(2010,Vancouver,Germany,10),(2010,Vancouver,Canada,14)},
-- (2010,Vancouver),{(2010,Vancouver,Canada,26),(2010,Vancouver,Germany,30),(2010,Vancouver,United States,37)})
join_top_3 = JOIN group_top_3_gold BY group, group_top_3_total BY group;

-- Need to use Rena's Jython
-- Register 'task2.py' using org.apache.pig.scripting.jython.JythonScriptEngine as udf;
-- report = FOREACH  grouped_by_year GENERATE udf.format_Bag(grouped_by_year);


