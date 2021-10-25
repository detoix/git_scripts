#!/bin/bash

i=0
file=0
timestamp=0
file_length=0
file_timestamp=0
file_max_timestamp=0

echo 'File' $'\t' 'File length [chars]' $'\t' 'Average last modification [timestamp]' $'\t' 'Last modification [timestamp]'

declare -A timestamp_by_dir
declare -A chars_by_dir

while read line
do
    if [[ $line == *"-_-"* ]]
    then
        if [ $file_length != "0" ] && [ $file_timestamp != "0" ]
        then
            path=`echo "$line" | sed -z 's/-_-//g'`

            echo $path $'\t' $file_length $'\t' $(( $file_timestamp / $file_length )) $'\t' $file_max_timestamp
            
            while [[ $path == *"/"* ]]
            do
                path=${path%/*}
                timestamp_by_dir[$path]=$((${timestamp_by_dir[$path]} + $file_timestamp))
                chars_by_dir[$path]=$((${chars_by_dir[$path]} + $file_length))
            done
        fi

        i=-1
        file_length=0
        file_timestamp=0
        file_max_timestamp=0
    elif (( i % 2 == 0 ))
    then
        timestamp="$line"
        file_max_timestamp=$(( $timestamp > $file_max_timestamp ? $timestamp : $file_max_timestamp ))
    elif (( i % 2 == 1 ))
    then
        file_length=$(( $file_length + ${#line} ))
        file_timestamp=$(( $file_timestamp + $timestamp * ${#line} ))
    fi

    i=$i+1
done < <(git ls-files *.cs --exclude-standard | xargs -I{} sh -c 'git blame {} --line-porcelain ; echo -_-{}' | sed -n 's/^committer-time //p;s/^\t//p;s/^-_-/-_-/p' | sed 's/\\//g')

for path in "${!timestamp_by_dir[@]}"
do
    echo $path $'\t' ${chars_by_dir[$path]} $'\t' $(( ${timestamp_by_dir[$path]} / ${chars_by_dir[$path]} )) $'\t' 0
done