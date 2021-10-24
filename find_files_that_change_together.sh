#!/bin/bash

number_of_commits_to_analyze=1000           #number of commits in analyzed git log
max_files_to_analyze_commit=30              #ignore merges, global renames etc
min_ratio_to_report_pair=20                 #ignore file pairs that do not change together
min_combined_commits_to_report_pair=20      #ignore file pairs that rarely change
min_shared_commits_to_report_pair=5         #ignore file pairs that rarely change

while getopts a:f:r:c:s: flag
do
    case "${flag}" in
        a) number_of_commits_to_analyze=${OPTARG};;
        f) max_files_to_analyze_commit=${OPTARG};;
        r) min_ratio_to_report_pair=${OPTARG};;
        c) min_combined_commits_to_report_pair=${OPTARG};;
        s) min_shared_commits_to_report_pair=${OPTARG};;
    esac
done

declare -A file_pair_commits_count
declare -A file_commits_count

while read commited_files
do
    files_in_commit=($(echo $commited_files | tr "," "\n"))
    files_in_commit_count=${#files_in_commit[@]}

    if (( $files_in_commit_count <= $max_files_to_analyze_commit ))
    then
        for ((i=0;i<$files_in_commit_count;i++))
        do
            file=${files_in_commit[$i]}
            file_commits_count[$file]=$((${file_commits_count[$file]} + 1))
            next_i=$i+1 

            for ((j=$next_i;j<$files_in_commit_count;j++)) 
            do
                other_file=${files_in_commit[$j]}
                file_pair_commits_count[$file,$other_file]=$((${file_pair_commits_count[$file,$other_file]} + 1))
            done
        done
    fi
done < <(git log --oneline --name-only --max-count=$number_of_commits_to_analyze --pretty=format:'---' | sed -z 's/---\n//g;s/\n/\t/g;s/\t\t/\n/g')

for pair in "${!file_pair_commits_count[@]}"
do
    combined_commits_to_pair=0

    for file_name in $(echo $pair | tr "," "\n")
    do
        combined_commits_to_pair=$((${file_commits_count[$file_name]} + $combined_commits_to_pair))
    done

    ratio=$((100 * ${file_pair_commits_count["$pair"]} / $combined_commits_to_pair))
    shared_commits=${file_pair_commits_count["$pair"]}

    if (( $ratio >= $min_ratio_to_report_pair )) && (( $combined_commits_to_pair >= $min_combined_commits_to_report_pair )) && (( $shared_commits >= $min_shared_commits_to_report_pair ))
    then    
        echo $pair' - share' $shared_commits' commits - '$combined_commits_to_pair' affect this pair - '$ratio'% of times both files are changed'
    fi

done
