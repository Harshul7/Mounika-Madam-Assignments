input_file="paragraph.txt"

# Ensure the file exists
if [ ! -f "$input_file" ]; then
  echo "Input file not found!"
  exit 1
fi

echo "1. Words - start with 's' and not followed by 'a':"
grep -oE '\bs[^aA[:space:]]\w*' "$input_file"
echo

echo "2. Words - start with 'w' and is followed by 'h':"
grep -oE '\bw\w*h\w*' "$input_file"
echo

echo "3. Words - start with 't' and is followed by 'h':"
grep -oE '\bt\w*h\w*' "$input_file"
echo

echo "4. Words - start with 'a' and not followed by 'n':"
grep -oE '\ba\b|\ba[^nN[:space:]]\w*' "$input_file"
#<< comment
#perl -oE '\ba(?!(nN))' "$input_file"
#comment 
echo