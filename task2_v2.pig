-- Default value incase there are no inputs from command line
%default START_YEAR 1800
%default END_YEAR 2100

-- Load data
medal_table = LOAD 'hdfs:///medal_table.csv' USING PigStorage(',') AS (year:int, country_code:chararray, gold:int, silver:int, bronze:int);
countries = LOAD 'hdfs:///countries.csv' USING PigStorage(',') AS (country_code:chararray, name:chararray, continent:chararray);
games = LOAD 'hdfs:///games.csv' USING PigStorage(',') AS (year:int, city:chararray, country_code:chararray);

-- Filter by start, end year if START_YEAR and END_YEAR parameters are inputed
medal_table = FILTER medal_table BY year >= $START_YEAR AND year <= $END_YEAR;
games = FILTER games BY year >= $START_YEAR AND year <= $END_YEAR;

-- Calculate total medals for each country each game
total_medal = FOREACH medal_table GENERATE year, country_code, gold, (gold + silver + bronze) AS total;

-- Join medal data with countries data by the country code
medal_country = JOIN total_medal BY country_code, countries BY country_code;
medal_country_selected = FOREACH medal_country
    GENERATE total_medal::year AS year, 
             total_medal::country_code AS country_code,
             countries::name AS name,
             total_medal::gold AS gold,
             total_medal::total AS total;

-- Join medal_country_selected with games data by the year
medal_country_game = JOIN medal_country_selected BY year, games BY year;
medal_country_game_selected = FOREACH medal_country_game
    GENERATE medal_country_selected::year AS year, 
             games::city AS city,
             medal_country_selected::name AS name,
             medal_country_selected::gold AS gold,
             medal_country_selected::total AS total;

-- Grouped by composite key (year, city) - easier to print out
grouped_year_city = GROUP medal_country_game_selected BY (year, city);

-- Output using jython
REGISTER 'hdfs:///task2.py' USING jython AS task2;
joined_result = FOREACH grouped_year_city {
    gold_sorted = ORDER medal_country_game_selected BY gold DESC, name ASC;
    top3_gold = LIMIT gold_sorted 3;
    gold_country = FOREACH top3_gold GENERATE name, gold;

    total_sorted = ORDER medal_country_game_selected BY total DESC, name ASC;
    top3_total = LIMIT total_sorted 3;
    total_country = FOREACH top3_total GENERATE name, total;

    GENERATE task2.format_output(
        group.year,
        group.city,
        gold_country,
        total_country
    ) AS final_output;
}

-- Store output
STORE joined_result INTO 'hdfs:///Output/task2' USING PigStorage();