:<<'COMMENT'
Use current directory if no argument provided
DIR is the variable for which we assign value based on the argument provided
if  $ bash shell-5.sh C:/shellscript then DIR="$1" that is C:/shellscript if no argument is passed then DIR="." that is current directory
COMMENT
# -n not empty
if [[ -n "$1" ]];then
    DIR="$1"
else
    DIR="."
fi

echo "> Directories:"

# Find directories recursively, count number of files in them, sort descending
:<<'abc'
 -type f: find all files
%h :directory path
sort:sorts the directory paths alphabetical order
uniq -c:counts how many files are present in each directory
sort -nr(numeric sort reverse order):sorts these counts based on biggest number first
abc
find "$DIR" -type f -printf '%h\n' | sort | uniq -c | sort -nr | while read count dir; do
  # Remove leading ./
  if [[ "$dir" == "." ]]; then
    dir="."
  else
    dir="${dir#./}" # a/b/c -> b/c
    # ./folder1/file1.txt

  fi
  echo "> ${dir}, ${count} file(s)"
done

echo
echo "> Files:"

# Find all files with sizes, sort descending
:<<'COMMENT'
-type f: find all files
-exec  stat --format="%s %n"{} +   For each file it runs the stat command to show size and name
stat: It is used to show detailed file info
--format: "%s%n" (file size and file name)
Ex:stat --format="%s%n" file1.txt
output:1234 file1.txt
{}  -->It is place holder in the find command when we use -exec,then it is replaced with the current file path found by find
+   ->By default -exec...{} \  runs the command separately for each file but if we add + at the end then "find" groups multiple file paths together and runs the command which takes less time and is more efficient

Example: find -type f -exec echo"File:" \;
output will be:
File:./file1.txt
File:./file2.txt
By using + find -type f -exec echo "Files are:" {}+
output will be:Files are:./file1.txt ./file2.txt

[[ "$file" == "./"* ]]; --> checks if the file starts with ./ if matched then it removes leading .from the variable $file 
${file#./} -parameter expansionthat removes the shortest match of ./ from thebeginning of $file
ex:
./file1.txt -->file1.txt
./file2.txt -->file2.txt

COMMENT

find "$DIR" -type f -exec stat --format="%s %n" {} + | sort -nr | while read size file; do
  # Remove leading ./
  if [[ "$file" == "./"* ]]; then
    file="${file#./}"
  fi
  echo "> $file"
done