CONTACTS_FILE="contacts.csv"

add_headers() {
    if [ ! -s "$CONTACTS_FILE" ]; then
        echo "FirstName,LastName,MobileNumber,CompanyName" > "$CONTACTS_FILE"
    fi
}

is_duplicate() {
    grep -i -q "^$1," "$CONTACTS_FILE"
}

insert_contact() {
    add_headers
    if is_duplicate "$1"; then
        echo "Contact with First Name '$1' already exists."
        exit 0
    fi
    echo "$1,$2,$3,$4" >> "$CONTACTS_FILE"
    echo "Contact inserted successfully."
}

edit_contact() {
    temp_file=$(mktemp)
    found=0
    while IFS=',' read -r fname lname mobile office; do
        if [ "$fname" == "$1" ]; then
            echo "$2,$3,$4,$5" >> "$temp_file"
            found=1
        else
            echo "$fname,$lname,$mobile,$office" >> "$temp_file"
        fi
    done < "$CONTACTS_FILE"
    mv "$temp_file" "$CONTACTS_FILE"
    
    if [[ $found -eq 1 ]];then
      echo "Contact edited." 
    else
      echo "Contact not found."
    fi 

}
#                     fname    lname      number        company 
#-C edit -k sundar -f satya -l nadella -n 9999999999 -o Microsoft

display_contacts() {
    add_headers
    header=$(head -n 1 "$CONTACTS_FILE")
    data=$(tail -n +2 "$CONTACTS_FILE")
    echo "$header"
    if [ "$1" == "asc" ]; then
        echo "$data" | sort -t',' -k1,1
    else
        echo "$data" | sort -t',' -k1,1r
    fi
}

search_contact() {
    case "$1" in
        "first name") col=1 ;;
        "last name") col=2 ;;
        "number") col=3 ;;
        *) echo "Invalid column"; exit 1 ;;
    esac
    
   # head -n 1 "$CONTACTS_FILE"
    awk -F',' -v val="$2" -v col="$col" 'tolower($col) == tolower(val)' "$CONTACTS_FILE"
}
#-C search -c "first name" -v sundar

delete_contact() {
    case "$1" in
        "first name") col=1 ;;
        "last name") col=2 ;;
        "number") col=3 ;;
        *) echo "Invalid column"; exit 1 ;;
    esac

    temp_file=$(mktemp)
    deleted=0

    {
        read -r header
        echo "$header"
        while IFS=',' read -r f1 f2 f3 f4; do
            fields=("$f1" "$f2" "$f3")
            if [[ "${fields[$((col - 1))],,}" == "${2,,}" ]]; then
            #-C delete -c "first name" -v Sundar
                deleted=1
                continue
            fi
            echo "$f1,$f2,$f3,$f4"
        done
    } < "$CONTACTS_FILE" > "$temp_file"

    mv "$temp_file" "$CONTACTS_FILE"

    if [ $deleted -eq 1 ]; then
        echo "Contact deleted successfully."
    else
        echo "No matching contact found to delete."
    fi
}

COMMAND=""
while getopts "C:f:l:n:o:k:c:v:ad" opt; do
    case $opt in
        C) COMMAND=$OPTARG ;;
        f) FNAME=$OPTARG ;;
        l) LNAME=$OPTARG ;;
        n) NUMBER=$OPTARG ;;
        o) COMPANY=$OPTARG ;;
        k) KEYNAME=$OPTARG ;;
        a) SORT_ASC=true ;;
        d) SORT_DESC=true ;;
        c) COLUMN=$OPTARG ;;
        v) VALUE=$OPTARG ;;
    esac
done

case "$COMMAND" in
    insert)
        insert_contact "$FNAME" "$LNAME" "$NUMBER" "$COMPANY"
        ;;
    edit)
        edit_contact "$KEYNAME" "$FNAME" "$LNAME" "$NUMBER" "$COMPANY"
        ;;
    display)
        if [ "$SORT_ASC" == "true" ]; then
            display_contacts "asc"
        elif [ "$SORT_DESC" == "true" ]; then
            display_contacts "desc"
        else
            echo "Specify -a (ascending) or -d (descending) for display."
        fi
        ;;
    search)
        search_contact "$COLUMN" "$VALUE"
        ;;
    delete)
        delete_contact "$COLUMN" "$VALUE"
        ;;
    *)
        echo "Invalid command"
        ;;
esac