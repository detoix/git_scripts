#!/bin/bash

i=0
file=0
timestamp=0
file_length=0
file_timestamp=0
file_max_timestamp=0

echo 'File' $'\t' 'File length' $'\t' 'Average last modification [timestamp]' $'\t' 'Last modification [timestamp]'

while read line
do
    if [[ $line == *"-_-"* ]]
    then
        if [ $file_length != "0" ] && [ $file_timestamp != "0" ]
        then
            echo $line $'\t' $file_length $'\t' $(( $file_timestamp / $file_length )) $'\t' $file_max_timestamp | sed -z 's/-_-//g'
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
