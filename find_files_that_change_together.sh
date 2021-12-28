#!/bin/bash

browse_commit_since=1990-01-01
max_files_to_analyze_commit=100             #ignore merges, global renames etc
min_shared_commits_to_report_pair=2         #ignore file pairs that rarely change

while getopts f:m:s: flag
do
    case "${flag}" in
        f) max_files_to_analyze_commit=${OPTARG};;
        m) min_shared_commits_to_report_pair=${OPTARG};;
        s) browse_commit_since=${OPTARG};;
    esac
done

declare -A file_pair_commits_count
declare -A file_commits_count

while read commited_files
do
    files_in_commit=($(echo $commited_files))
    files_in_commit_count=${#files_in_commit[@]}

    if (( $files_in_commit_count <= $max_files_to_analyze_commit ))
    then
        for ((i=0;i<$files_in_commit_count;i++))
        do
            file=${files_in_commit[$i]}
            file_directory="${file%/*}" #jump to parent directory
            file_commits_count[$file]=$((${file_commits_count[$file]} + 1))
            next_i=$i+1 

            for ((j=$next_i;j<$files_in_commit_count;j++)) 
            do
                other_file=${files_in_commit[$j]}
                other_file_directory="${other_file%/*}" #jump to parent directory

                if [ "$file_directory" != "$other_file_directory" ]
                then
                    file_pair_commits_count[$file,$other_file]=$((${file_pair_commits_count[$file,$other_file]} + 1))
                fi
            done
        done
    fi
done < <(git log --oneline --name-only --since=$browse_commit_since --pretty=format:'' | sed -z 's/\n/\t/g;s/\t\t/\n/g')

for pair in "${!file_pair_commits_count[@]}"
do
    shared_commits=${file_pair_commits_count["$pair"]}

    if (( $shared_commits >= $min_shared_commits_to_report_pair ))
    then    
        echo $pair','$shared_commits',shared commits'
    fi
done
