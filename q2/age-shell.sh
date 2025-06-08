input_file="input.txt"
output_file="output.txt"
> "$output_file"

while read -r line || [[ -n $line ]]; do # reads file line by line and if the last line doesnot end with a new line we use [[ -n $line ]] so that it ensures to read the last line
    # Remove carriage return
    line=$(echo "$line" | tr -d '\r')

    dob=${line##* }
    name=${line%" $dob"}

    # Split DOB into day/month/year
    day=${dob%%/*}
    rest=${dob#*/}
    month=${rest%%/*}
    year=${rest##*/}

    
    birthdate=$(date -d "$year-$month-$day" +%Y-%m-%d 2>/dev/null)
    if [[ -z "$birthdate" ]]; then 
        continue
    fi
#Always use 10# when performing arithmetic operations with numbers which have leading zeroes(if a number starts with leading 0 then it is interpreted as octal)
#ex:echo $((08+1)) gives error but echo $((10#08+1)  gives 9
    
    birth_y=$((10#$(date -d "$birthdate" +%Y)))
    birth_m=$((10#$(date -d "$birthdate" +%m)))
    birth_d=$((10#$(date -d "$birthdate" +%d)))

    now_y=$((10#$(date +%Y)))
    now_m=$((10#$(date +%m)))
    now_d=$((10#$(date +%d)))

    # Calculate difference
    y=$((now_y - birth_y))
    m=$((now_m - birth_m))
    d=$((now_d - birth_d))

# check if we get negative d value ,if it is negative then decrease month by 1 and add the total no of days in the previous month to the day count
    if (( d < 0 )); then
        m=$((m - 1))
        prev_year_month=$(date -d "$(date +%Y-%m-01) -1 day" +%Y-%m)  # date +%Y-%m-01:first day of the current month  /  -1 day:moves back to the last day of the previous month   /+%Y-%m -get the year and month like 2025-04
        days_in_prev_month=$(date -d "$prev_year_month-01 +1 month -1 day" +%d)  # takes the first day of the month and add one month and subtract 1 day to get the last day of the previous month
        d=$((d + days_in_prev_month)) # adjust the days by adding the days from the previous month
    fi

# check if month is negative then subtract 1 from year and add 12 to the months
    if (( m < 0 )); then
        y=$((y - 1))
        m=$((m + 12))
    fi
#example: Birthdate is dec 30 1995/ today: may 27,2025
#calculate difference : year=2025-1995=30 month=5-12=-7(negative) day=27-30=-3(negative)
#first we will adjust days:
# d=-3 1)subtract 1 from month==>m=-7-1=-8   2) find previous month from may which is april==> 2025-04   3)days in previous month (april=30)  4)add 30 to the d==>d=-3+30=27
# m=-8 1)Subtract 1 from year==> y=30-1=29  2)Add 12 to the month==>m=-8+12=4    
#   29 years 4 month 27 days

    echo "$name $y years $m months $d days" >> "$output_file"
done < "$input_file"