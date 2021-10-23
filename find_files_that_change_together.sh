#!/bin/bash

declare -A file_pair_commits_count
declare -A file_commits_count

while read commited_files
do
    files_in_commit=($(echo $commited_files | tr "," "\n"))
    files_in_commit_count=${#files_in_commit[@]}

    if (( $files_in_commit_count < 30 ))
    then    
        for ((i=0;i<$files_in_commit_count;i++))
        do
            file=${files_in_commit[$i]}
            file_commits_count[$file]=$((${file_commits_count[$file]} + 1))
            next_i=i+1

            for ((j=$next_i;j<$files_in_commit_count;j++)) 
            do
                other_file=${files_in_commit[$j]}
                file_pair_commits_count[$file,$other_file]=$((${file_pair_commits_count[$file,$other_file]} + 1))
            done
        done
    fi
done < <(git log --oneline --name-only --max-count=1000 --pretty=format:'---' | sed -z 's/---\n//g;s/\n/\t/g;s/\t\t/\n/g')

for pair in "${!file_pair_commits_count[@]}"
do
    total_commits_to_pair=0

    for file_name in $(echo $pair | tr "," "\n")
    do
        total_commits_to_pair=$((${file_commits_count[$file_name]} + $total_commits_to_pair))
    done

    ratio=$((100 * ${file_pair_commits_count["$pair"]} / $total_commits_to_pair))
    shared_commits=${file_pair_commits_count["$pair"]}

    if (( $ratio > 20 )) && (( $total_commits_to_pair > 10 )) && (( $shared_commits > 5 ))
    then    
        echo $pair' - share' $shared_commits' commits - '$total_commits_to_pair' affect this pair - '$ratio'% of times both files are changed'
    fi

done