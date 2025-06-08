mask_words() {
    while read -r line; do
        for word in $line; do
            if [ -z "$word" ]; then
                continue
            fi
            if [ ${#word} -le 4 ]; then
                echo -n "$word "
            else
                prefix=${word:0:4}
                masked=$(printf '%*s' $((${#word} - 4)) '' | tr ' ' '#')
                echo -n "$prefix$masked "
            fi
        done
        echo 
    done < "$1"
}

echo -e "Programming is my passion" > input.txt
mask_words input.txt