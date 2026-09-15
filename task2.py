#!/usr/bin/env python
import sys

# (2014,{(2014,United States,Sochi,9,28)})
@outputSchema("year:bag{t:tuple(year:int,country_name:chararray, host_city:chararray, gold:int, total_medals:int)}") 
def format_Bag(bag):
   output_Bag = []
   current_year = None
   count = 0
   
   for word in bag:
        parts = word.split(",")
     
        if len(parts) != 5:
            continue
   
        year = int(parts[0])
        country_name = parts[1]
        host_city = parts[2]
        gold = int(parts[3])
        total_medals = int(parts[4])
        
        if current_year is None:
            current_year = year
        else:
            
            output_Bag.append((year, country_name, host_city, gold, total_medals))
   
    return output_Bag

