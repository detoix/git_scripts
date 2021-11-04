#!/bin/bash

analyze_every_nth_commit=100
browse_commit_since=1900-01-01
max_number_of_commits=-1
filter_files='*.cs'

while getopts e:s:m:f: flag
do
    case "${flag}" in
        e) analyze_every_nth_commit=${OPTARG};;
        s) browse_commit_since=${OPTARG};;
        m) max_number_of_commits=${OPTARG};;
        f) filter_files=${OPTARG};;
    esac
done

echo 'Date' 'Commit_hash' 'Leading_spaces' 'Lines_count'

i=0
while read line
do
    if (( i % $analyze_every_nth_commit == 0 ))
    then
        $(git checkout -f --quiet $line)

        files=$(echo git ls-files $filter_files)

        echo \
$(git log -1 --format='%cs %h') \
$($files | xargs -I{} grep -o '^[[:blank:]]*' {} | wc -c) \
$($files | xargs -I{} cat {} | wc -l)

    fi

    i=$i+1
done < <(git rev-list --since=$browse_commit_since --max-count=$max_number_of_commits --reverse HEAD)

$(git checkout -f --quiet master)
