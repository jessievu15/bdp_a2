%default START_YEAR 1800
%default END_YEAR 2100

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

-- Load the games file
games = load 'hdfs:///games.csv'
    using PigStorage(',') 
    as (year:int, host_city:chararray, host_country_code:chararray);

-- Joins
join_medals = JOIN medals_filtered BY country_code, countries BY country_code;

medals_type = FOREACH join_medals GENERATE
    medals_filtered::year AS year,
    countries::country_name AS country_name,
    medals_filtered::gold AS gold,
    medals_filtered::silver AS silver,
    medals_filtered::bronze AS bronze;

medals_with_host_city = JOIN medals_type BY year, games BY year;

total_medals_count = FOREACH medals_with_host_city GENERATE
    medals_type::year AS year,
    medals_type::country_name AS country_name,
    games::host_city AS host_city,
    (medals_type::gold + medals_type::silver + medals_type::bronze) AS total_medals;

gold_medals_count = FOREACH medals_with_host_city GENERATE
    medals_type::year AS year,
    medals_type::country_name AS country_name,
    games::host_city AS host_city,
    medals_type::gold AS gold;

-- Order
grouped_total_medals = GROUP total_medals_count BY year;
grouped_gold_medals = GROUP gold_medals_count BY year;

top3_total_medals = FOREACH grouped_total_medals {
    sorted_total = ORDER total_medals_count BY total_medals DESC;
    top3 = LIMIT sorted_total 3;
    GENERATE group AS year, top3;
};

top3_gold_medals = FOREACH grouped_gold_medals {
    sorted_gold = ORDER gold_medals_count BY gold DESC;
    top3 = LIMIT sorted_gold 3;
    GENERATE group AS year, top3;
};

join_top3 = JOIN top3_total_medals BY year, top3_gold_medals BY year;

Register 'hdfs:///task2.py' using jython as task2;
report_results = FOREACH join_top3 { 
    gold_full     = top3_gold_medals::top3;
    gold_country  = FOREACH top3_gold_medals::top3 GENERATE country_name, gold;
    total_country = FOREACH top3_total_medals::top3 GENERATE country_name, total_medals;
    GENERATE task2.format_output(
        top3_gold_medals::year,
        gold_full,
        gold_country,
        total_country
        ) AS final_output;
};

-- Store output
STORE report_results INTO 'hdfs:///Output/task2' USING PigStorage();
