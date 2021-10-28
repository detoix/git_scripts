#!/bin/bash

i=0

echo 'File'$'\t''File length [chars]'$'\t''Average last modification [timestamp]'$'\t''Last modification [timestamp]'$'\t''Leading curly braces [count]'

while read line
do
    if (( i % 20 == 0 ))
    then
        $(git checkout --quiet $line)

        echo $(git ls-files *.cs --exclude-standard | xargs -I{} grep -o '^[[:blank:]]' {} | wc -c)$'\t'$(git log -1 --format=%cs)
    fi

    i=$i+1
done < <(git rev-list --reverse HEAD)

$(git checkout --quiet master)
