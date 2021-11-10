#!/bin/bash

filter_files='*.cs'

while getopts f:rlca flag
do
    case "${flag}" in
        f) filter_files=${OPTARG};;
        r) print_raw_data=true;;
        l) print_lines=true;;
        c) print_complexity=true;;
        a) print_age=true;;
    esac
done

i=0
file_length=0
file_leading_spaces=0
file_timestamp=0

declare -A timestamp_by_dir
declare -A lines_by_dir
declare -A leading_spaces_by_dir

if [ $print_raw_data ]
then
    echo 'File' 'Lines_count' 'Average_last_modification_timestamp' 'Last_modification_timestamp' 'Leading_spaces'
fi

while read line
do
    if (( i % 4 == 0 )) #line with timestamp
    then
        file_timestamp="$line"
    elif (( i % 4 == 1 )) #line with lines length
    then
        file_length="$line"
    elif (( i % 4 == 2 )) #line with leading spaces count
    then
        file_leading_spaces="$line"
    elif (( i % 4 == 3 )) #line with name
    then
        path="$line"

        if [ $print_raw_data ]
        then
            echo "$path" $file_length $file_timestamp $file_max_timestamp $file_leading_spaces #report single file data
        fi

        while [[ "$path" == *"/"* ]] #iterate recursively to parent directory
        do
            path="${path%/*}" #jump to parent directory
            timestamp_by_dir["$path"]=$((${timestamp_by_dir["$path"]} + $file_timestamp * $file_length))
            lines_by_dir["$path"]=$((${lines_by_dir["$path"]} + $file_length))
            leading_spaces_by_dir["$path"]=$((${leading_spaces_by_dir["$path"]} + $file_leading_spaces))
        done
    fi

    i=$i+1
done < <(git ls-files "$filter_files" | xargs -I{} sh -c 'git log -1 --format=%ct "{}" ; cat "{}" | wc -l ; grep -o '^[[:blank:]]*' "{}" | tr -d "\n" | wc -c ; echo "{}"')

#^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^
#list all files
#print debug blame data with ~path at the end
#keep only lines with timestamp, code and file path
#replace whitespaces with _ - required because process substitution removes leading spaces for some reason

declare -A directories_2d_array #declare structure expected by diagram
declare -A data_source

i=0
max_depth=0
timestamp=$(date +%s)

for key in "${!leading_spaces_by_dir[@]}" #keys are the same for any data array
do
    if [ $print_lines ] || [ -z "${lines_by_dir["$key"]}" ] || [ "${lines_by_dir["$key"]}" = "0" ]
    then
        data_source["$key"]="${lines_by_dir["$key"]}"
    elif [ $print_complexity ]
    then
        leading_spaces_per_line=$(( ${leading_spaces_by_dir["$key"]} / ${lines_by_dir["$key"]} ))
        data_source["$key"]=$(( $leading_spaces_per_line * $leading_spaces_per_line ))
    elif [ $print_age ]
    then
        directory_age_in_secons=$(( ${timestamp_by_dir["$key"]} / ${lines_by_dir["$key"]} ))
        age_in_seconds=$(( $timestamp - $directory_age_in_secons ))
        age_in_days=$(( $age_in_seconds / 86400 ))
        data_source["$key"]="$age_in_days"
    fi
done

while read path
do
    depth=($(echo $path | grep -o '/' | tr -d '\n' | wc -c)) #count directory depth
    max_depth=$(( $depth > $max_depth ? $depth : $max_depth ))
    directories_2d_array[$i,$depth]="$path"

    printf "$path" #print spreadsheet header
    printf '\t'  #separated with tabs

    i=$(( $i+1 ))
done < <(printf '%s\n' "${!data_source[@]}" | sed 's/\//,/g' | sort | sed 's/,/\//g') #loop through all stored directories sorted as strings

echo '' #break line

# for i in $(seq 0 ${#directories_2d_array[@]}) #loop through all columns
# do
#     for (( j=0; j<$max_depth; j++ ))
#     do
#         if [ ! -z "${directories_2d_array[$i,$j]}" ] #current value is calculated directly
#         then
#             printf "%s,%s" $(echo "${directories_2d_array[$i,$j]}")

#             for (( k=$j, k<$max_depth; k++ ))
#             do
#                 printf ','
#             done

#             printf "${lines_by_dir["${directories_2d_array[$i,$j]}"]}"
#             printf ","
#             printf "${data_source["${directories_2d_array[$i,$j]}"]}"
#             printf "\n"
#         fi
#     done
# done

for (( j=0; j<=$max_depth; j++ ))
do 
    for i in $(seq 0 ${#directories_2d_array[@]}) #loop through all columns
    do
        if [ ! -z "${directories_2d_array[$i,$j]}" ] #current value is calculated directly
        then
            printf "${data_source["${directories_2d_array[$i,$j]}"]}" #print value for directory in current place in 2d array
        elif [ $j != 0 ] && [ ! -z "${directories_2d_array[$i,$(($j-1))]}" ] #there's anything in parent directory (above)
        then
            sum_in_this_dir_children=0
            forward_iterator=$(( $i + 1 ))
            while [ -z "${directories_2d_array[$forward_iterator,$(($j-1))]}" ] && [ $forward_iterator -lt "${#directories_2d_array[@]}" ] #loop through any possible children of current directory until reach end of 2d array
            do
                if [ ! -z "${directories_2d_array[$forward_iterator,$j]}" ] #any child containing value
                then
                    sum_in_this_dir_children=$(( $sum_in_this_dir_children + "${data_source["${directories_2d_array[$forward_iterator,$j]}"]}" )) #aggregate sum
                fi

                forward_iterator=$(( $forward_iterator + 1 ))
            done

            current_value=$(( "${data_source["${directories_2d_array[$i,$(($j-1))]}"]}" - $sum_in_this_dir_children ))

            if [ $current_value -gt 0 ] #anything in this directory
            then
                next_level="${directories_2d_array[$i,$(($j-1))]}-${j}" #create some key for cell in row below
                directories_2d_array[$i,$j]=$next_level #assign fake key so it appears in loop through row below
                data_source[$next_level]=$current_value #assign value to fake key so it it used in loop through row below
            fi

            if [ $print_lines ]
            then
                printf $current_value
            fi
        fi
        
        printf '\t'
    done

    echo ''
done