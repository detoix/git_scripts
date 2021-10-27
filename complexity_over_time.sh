#!/bin/bash

i=0

echo 'Indentation spaces'$'\t''Commit age'

while read line
do
    if (( i % 20 == 0 ))
    then
        $(git checkout --quiet $line)

        echo $(git ls-files *.cs --exclude-standard | xargs -I{} grep -o '^[[:blank:]]' {} | wc -c)$'\t'$(git log -1 --format=%cr)
    fi

    i=$i+1
done < <(git rev-list HEAD)

$(git checkout --quiet master)
