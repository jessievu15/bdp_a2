@outputSchema("final_output:chararray")
def format_output(year, city, gold_country, total_country):

    def per_line(bag):
        parts = []
        i = 1
        for field in bag:
            name = field[0]
            medal = field[1]
            parts.append("%d. %s (%d)" % (i, name, medal))
            i += 1
        return " | ".join(parts)

    lines = []
    lines.append("%d %s"% (year, city))
    lines.append("By Gold Medals:")
    lines.append(per_line(gold_country))
    lines.append("By Total Medals:")
    lines.append(per_line(total_country))

    return "\n".join(lines) + "\n"