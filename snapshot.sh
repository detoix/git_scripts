#!/bin/bash

filter_files='*.cs'

while getopts f: flag
do
    case "${flag}" in
        f) filter_files=${OPTARG};;
    esac
done

i=0
file=0
timestamp=0
file_length=0
file_leading_spaces=0
file_timestamp=0
file_max_timestamp=0

declare -A timestamp_by_dir
declare -A chars_by_dir
declare -A max_timestamp_by_dir
declare -A leading_spaces_by_dir

echo 'File' 'Lines_count' 'Average_last_modification_timestamp' 'Last_modification_timestamp' 'Leading_spaces'

while read line
do
    if [[ $line == *"~"* ]] #file path is prefixed with ~
    then
        if [ $file_length != "0" ] #avoid division by zero
        then
            path="${line#?}" #remove leading ~ from file path
            
            echo $path $file_length $(( $file_timestamp / $file_length )) $file_max_timestamp $file_leading_spaces #report single file data

            while [[ $path == *"/"* ]] #iterate recursively to parent directory
            do
                path=${path%/*} #jump to parent directory
                timestamp_by_dir[$path]=$((${timestamp_by_dir[$path]} + $file_timestamp))
                chars_by_dir[$path]=$((${chars_by_dir[$path]} + $file_length))
                leading_spaces_by_dir[$path]=$((${leading_spaces_by_dir[$path]} + $file_leading_spaces))

                if [ -z "${max_timestamp_by_dir[$path]}" ] #set if does not exist, required because of some bug
                then
                    max_timestamp_by_dir[$path]=0
                fi

                max_timestamp_by_dir[$path]=$(( ${max_timestamp_by_dir[$path]} > $file_max_timestamp ? ${max_timestamp_by_dir[$path]} : $file_max_timestamp ))
            done
        fi

        i=-1 #return iterator to odd for next file
        file_length=0
        file_timestamp=0
        file_max_timestamp=0
        file_leading_spaces=0
    elif (( i % 2 == 0 )) #line with timestamp
    then
        timestamp="$line"
        file_max_timestamp=$(( $timestamp > $file_max_timestamp ? $timestamp : $file_max_timestamp ))
    elif (( i % 2 == 1 )) #line with code
    then
        file_length=$(( $file_length + 1 ))
        file_timestamp=$(( $file_timestamp + $timestamp ))
        file_leading_spaces=$(( $file_leading_spaces + $(echo $line | grep -o '^_*' | tr -d '\n' | wc -c) ))       
    fi

    i=$i+1
done < <(git ls-files $filter_files | \
        xargs -I{} sh -c 'git blame {} --line-porcelain ; echo ~{}' | \
        sed -n 's/^committer-time //p;s/^\t//p;s/^~/~/p' | \
        sed 's/\\//g;s/ /_/g')

#^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^
#list all files
#print debug blame data with ~path at the end
#keep only lines with timestamp, code and file path
#replace whitespaces with _ - required because process substitution removes leading spaces for some reason

for path in "${!timestamp_by_dir[@]}" #iterate over previously prepared directories data
do
    echo $path ${chars_by_dir[$path]} $(( ${timestamp_by_dir[$path]} / ${chars_by_dir[$path]} )) ${max_timestamp_by_dir[$path]} ${leading_spaces_by_dir[$path]}
done

# declare -A arr

# x=0
# y=0
# max_depth=0

# while read path
# do
#     depth=($(echo $path | grep -o '/' | tr -d '\n' | wc -c))
#     max_depth=$(( $depth > $max_depth ? $depth : $max_depth ))
#     arr[$x,$depth]=$path

#     printf $path
#     printf '\t'

#     x=$(( $x+1 ))
# done < <(echo ${!leading_spaces_by_dir[@]} | tr " " "\n" | sort)

# echo ''

# for (( j=0; j<=$max_depth; j++ ))
# do 
#     for i in $(seq 0 ${#arr[@]})
#     do
#         if [ ! -z ${arr[$i,$j]} ]
#         then
#             printf ${leading_spaces_by_dir[${arr[$i,$j]}]}
#         elif [ $j != 0 ] && [ ! -z ${arr[$i,$(($j-1))]} ]
#         then
#             sum_in_this_dir=0
#             forward_iterator=$(( $i + 1 ))
#             while [ -z ${arr[$forward_iterator,$(($j-1))]} ] && [ $forward_iterator -lt ${#arr[@]} ]
#             do
#                 if [ ! -z ${arr[$forward_iterator,$j]} ]
#                 then
#                     sum_in_this_dir=$(( $sum_in_this_dir + ${leading_spaces_by_dir[${arr[$forward_iterator,$j]}]} ))
#                 fi

#                 forward_iterator=$(( $forward_iterator + 1 ))
#             done

#             current_value=$(( ${leading_spaces_by_dir[${arr[$i,$(($j-1))]}]} - $sum_in_this_dir ))

#             if [ $current_value -gt 0 ]
#             then
#                 next_level="${arr[$i,$(($j-1))]}-${j}"
#                 arr[$i,$j]=$next_level
#                 leading_spaces_by_dir[$next_level]=$current_value
#             fi

#             printf $current_value
#         fi
        
#         printf '\t'
#     done

#     echo ''
# done

#git log --format=format: --name-only | egrep -v '^$' | sort | uniq -c | sort -r | head -5

#todo: srednia ilosc autorów 1 pliku
