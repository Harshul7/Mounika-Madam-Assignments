input_file="input.txt"
output_file="output.txt"
> "$output_file"

while read -r line  ; do
    #line= $(echo "$line" | tr -d '\r')
    # Extract date of birth (last word)
    dob=${line##* }
    # Extract name (everything except last word)
    name=${line%" $dob"}

    day=${dob%%/*} # (Removes the longest match starting from a / till the end)
    rest=${dob#*/} #removes dd
# rest=mm/yyyy
    month=${rest%%/*} #removes yyyy
    year=${rest##*/} # removes mm. ( Removes the longest match ending with a / from the start)

    today=$(date +%s)
    birthdate=$(date -d "$year-$month-$day" +%s 2>/dev/null)

    if [ -n "$birthdate" ]; then
        age=$(( (today - birthdate) / (365*24*60*60) ))
        echo "$name $age" >> "$output_file"
    fi
done < "$input_file"