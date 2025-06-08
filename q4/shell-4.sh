input_file="input1.txt"
stopwords_file="stopwords.txt"
searchword_file="search_word.txt"
output_file="Output.txt"

# Make sure all files exist
if [[ ! -f "$input_file" || ! -f "$stopwords_file" || ! -f "$searchword_file" ]]; then
    echo "One or more input files missing!"
    exit 1
fi


# Empty output file before writing
> "$output_file"

# Read each search word
while read -r search_word || [[ -n "$search_word" ]]; do
    # Convert to lowercase
    search_word=$(echo "$search_word" | tr '[:upper:]' '[:lower:]')
    if [ -z "$search_word" ]; then
         continue
    fi

    # Read each sentence
    while read -r sentence || [[ -n "$sentence" ]]; do
#multiline comment
:<<'COMMENT'
converts the sentence to lowercase and removes all characters except letters,numbers,spaces and new lines
tr ' ' '\n'  -->converts the senetence to a list of words(one word per line)  and it uses grep-vxf "$stopwords_file"  removes stop words from list of words
-v:invert the match  .usually grep print the lines that match the pattern,but when we use -v:it prints the lines that does not match the pattern
-x:match the whole line that means a line is considered match only if the entire line matches the pattern
-f: each line of the stopwords.txt file is considered a pattern to match exactly
        
example: 
        the 
        quick brown
	fox
	jumps
	over
	the
	lazy
	dog
        If stopwords.txt contains 
	the
	over	
	the grep -vxf matches "the" and "over" and removes them --> the output will be:
	quick	
	brown		
	fox	
	jumps
	lazy	
	dog
Now  xargs takes new line separated words and combines into single space separated line which becomes: "quick brown fox jumps lazy dog"
COMMENT
        no_stopwords=$(echo "$sentence" | tr '[:upper:]' '[:lower:]' | tr -cd 'a-z0-9 \n' | tr ' ' '\n' | grep -vxf "$stopwords_file" | xargs) 
     
        # Count total words
        total_words=$(echo "$no_stopwords" | wc -w) # wc:word count  -w:count number of words
        
        # Count how many times search_word occurs
        match_count=$(echo "$no_stopwords" | grep -wo "$search_word" | wc -l) # -o: prints only the matched part    /-w:match whole words not substrings   /wc -l: counts how many lines are returned and stores the result in match_count variable


        # Calculate term frequency and stores it in tf rounded to 4 decimal places
        if (( total_words > 0 )); then
            tf=$(awk "BEGIN {printf \"%.4f\", $match_count/$total_words}")
        else
            tf="0.0000"
        fi

:<<'COMMENT'
awk "BEGIN"{...}: This means it executed the code inside the begin immediately without waiting for the input lines
printf "%4f": prints the floating point number withh 4digits after the decimal point
COMMENT
        # Output result
        echo "$search_word: $no_stopwords, <$tf>" >> "$output_file"

    done < "$input_file"

done < "$searchword_file"

echo "Done! Results saved in $output_file"

:<<'COMMENT'
This is a multi line comment.                
COMMENT