#!/bin/bash

i=0

echo 'Date'$'\t''Leading_spaces'$'\t''Lines_count'$'\t''Total_chars'

while read line
do
    if (( i % 20 == 0 ))
    then
        $(git checkout --quiet $line)

        files=$(echo git ls-files *.cs)

        echo \
$(git log -1 --format=%cs)\
 \
$($files | xargs -I{} grep -o '^[[:blank:]]*' {} | wc -c)\
 \
$($files | xargs -I{} cat {} | wc -ml)

    fi

    i=$i+1
done < <(git rev-list --reverse HEAD)

$(git checkout --quiet master)
