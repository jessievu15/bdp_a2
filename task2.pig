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

-- Join
medal_country = JOIN total_medal BY country_code, countries BY country_code;
medal_country_selected = FOREACH medal_country
    GENERATE total_medal::year AS year, 
             total_medal::country_code AS country_code,
             countries::name AS name,
             total_medal::gold AS gold,
             total_medal::total AS total;

gYear = GROUP medal_country_selected BY year;

-- Get the top 3 countries and order in descending
top3_gold = FOREACH gYear {
    sorted = ORDER medal_country_selected BY gold DESC, name ASC;
    top3 = LIMIT sorted 3;
    GENERATE FLATTEN(top3) AS (year, country_code, name, gold, total);
}
top3_total = FOREACH gYear {
    sorted = ORDER medal_country_selected BY total DESC, name ASC;
    top3 = LIMIT sorted 3;
    GENERATE FLATTEN(top3) AS (year, country_code, name, gold, total);
}

-- Join
gold_game = JOIN top3_gold BY year, games BY year;
gold_game_result = FOREACH gold_game
    GENERATE top3_gold::year AS year,
             games::city AS city,
             top3_gold::name AS name,
             top3_gold::gold AS gold;

gGold_game = GROUP gold_game_result BY (year, city);

total_game = JOIN top3_total BY year, games BY year;
total_game_result = FOREACH total_game
    GENERATE top3_total::year AS year,
             games::city AS city,
             top3_total::name AS name,
             top3_total::total AS total;
gTotal_game = GROUP total_game_result BY (year, city);

-- Join
joined_games = JOIN gGold_game BY group, gTotal_game BY group;

REGISTER 'hdfs:///task2.py' USING jython AS task2;
joined_result = FOREACH joined_games {
    gold_sorted = ORDER gGold_game::gold_game_result BY gold DESC, name ASC;
    gold_country = FOREACH gold_sorted GENERATE name, gold;
    total_sorted = ORDER gTotal_game::total_game_result BY total DESC, name ASC;
    total_country = FOREACH total_sorted GENERATE name, total;
    GENERATE task2.format_output(
        gGold_game::group.year,
        gGold_game::group.city,
        gold_country,
        total_country
    ) AS final_output;
}

STORE joined_result INTO 'hdfs:///Output/task2' USING PigStorage();

