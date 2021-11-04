#!/bin/bash

i=0
file=0
timestamp=0
file_length=0
file_leading_spaces=0
file_timestamp=0
file_max_timestamp=0

declare -A timestamp_by_dir
declare -A chars_by_dir
declare -A max_timestamp_by_dir
declare -A leading_spaces_by_dir

echo 'File' 'Lines_count' 'Average_last_modification_timestamp' 'Last_modification_timestamp' 'Leading_spaces'

while read line
do
    if [[ $line == *"-_-"* ]]
    then
        if [ $file_length != "0" ]
        then
            path=`echo "$line" | sed -z 's/-_-//g'`

            echo $path $file_length $(( $file_timestamp / $file_length )) $file_max_timestamp $file_leading_spaces
            
            while [[ $path == *"/"* ]]
            do
                path=${path%/*}
                timestamp_by_dir[$path]=$((${timestamp_by_dir[$path]} + $file_timestamp))
                chars_by_dir[$path]=$((${chars_by_dir[$path]} + $file_length))
                leading_spaces_by_dir[$path]=$((${leading_spaces_by_dir[$path]} + $file_leading_spaces))

                if [ -z "${max_timestamp_by_dir[$path]}" ]
                then
                    max_timestamp_by_dir[$path]=0
                fi

                max_timestamp_by_dir[$path]=$(( ${max_timestamp_by_dir[$path]} > $file_max_timestamp ? ${max_timestamp_by_dir[$path]} : $file_max_timestamp ))
            done
        fi

        i=-1
        file_length=0
        file_timestamp=0
        file_max_timestamp=0
        file_leading_spaces=0
    elif (( i % 2 == 0 ))
    then
        timestamp="$line"
        file_max_timestamp=$(( $timestamp > $file_max_timestamp ? $timestamp : $file_max_timestamp ))
    elif (( i % 2 == 1 ))
    then
        file_length=$(( $file_length + 1 ))
        file_timestamp=$(( $file_timestamp + $timestamp ))
        file_leading_spaces=$(echo grep -o '^[[:blank:]]*' "$line" | wc -c)
    fi

    i=$i+1
done < <(git ls-files *.cs | xargs -I{} sh -c 'git blame {} --line-porcelain ; echo -_-{}' | sed -n 's/^committer-time //p;s/^\t//p;s/^-_-/-_-/p' | sed 's/\\//g')

for path in "${!timestamp_by_dir[@]}"
do
    echo $path ${chars_by_dir[$path]} $(( ${timestamp_by_dir[$path]} / ${chars_by_dir[$path]} )) ${max_timestamp_by_dir[$path]} ${leading_spaces_by_dir[$path]}
done

#git log --format=format: --name-only | egrep -v '^$' | sort | uniq -c | sort -r | head -5

#todo: srednia ilosc autorów 1 pliku
