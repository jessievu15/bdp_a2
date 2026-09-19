@outputSchema("final_output:chararray") 
def format_output(year,gold_full,gold,total):
    city = gold_full[0][2]
    
    def format_bag(bag):
        parts = []
        for i,field in enumerate(bag,start=1):
            name = field[0]
            count = field[1]
            parts.append("%d. %s (%d)" % (i, name, count))
            
        return " | ".join(parts)
    
    lines = []
    lines.append("%d %s"% (year, city))
    lines.append("By Gold Medals:")
    lines.append(format_bag(gold))
    lines.append("By Total Medals:")
    lines.append(format_bag(total))
    
    return "\n".join(lines) + "\n"
      
        
        
        
        
