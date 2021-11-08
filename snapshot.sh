#!/bin/bash

filter_files='*.cs'

while getopts f:r flag
do
    case "${flag}" in
        f) filter_files=${OPTARG};;
        r) print_raw_data=true;;
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

if [ $print_raw_data ]
then
    echo 'File' 'Lines_count' 'Average_last_modification_timestamp' 'Last_modification_timestamp' 'Leading_spaces'
fi

while read line
do
    if [[ $line == *"~"* ]] #file path is prefixed with ~
    then
        if [ $file_length != "0" ] #avoid division by zero
        then
            path="${line#?}" #remove leading ~ from file path
            
            if [ $print_raw_data ]
            then
                echo $path $file_length $(( $file_timestamp / $file_length )) $file_max_timestamp $file_leading_spaces #report single file data
            fi

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

if [ $print_raw_data ]
then
    for path in "${!leading_spaces_by_dir[@]}" #iterate over previously prepared directories data
    do
        echo $path ${chars_by_dir[$path]} $(( ${timestamp_by_dir[$path]} / ${chars_by_dir[$path]} )) ${max_timestamp_by_dir[$path]} ${leading_spaces_by_dir[$path]}
    done

    exit 1
fi

declare -A directories_2d_array #declare structure expected by diagram
declare -A data_source

i=0
max_depth=0

for key in ${!leading_spaces_by_dir[@]}; do #keys are the same for any data array
    data_source["$key"]="${chars_by_dir["$key"]}"
done

while read path
do
    depth=($(echo $path | grep -o '/' | tr -d '\n' | wc -c)) #count directory depth
    max_depth=$(( $depth > $max_depth ? $depth : $max_depth ))
    directories_2d_array[$i,$depth]=$path

    printf $path #print spreadsheet header
    printf '\t'  #separated with tabs

    i=$(( $i+1 ))
done < <(echo ${!data_source[@]} | tr " " "\n" | sort) #loop through all stored directories sorted as strings

echo '' #break line

for (( j=0; j<=$max_depth; j++ ))
do 
    for i in $(seq 0 ${#directories_2d_array[@]}) #loop through all columns
    do
        if [ ! -z ${directories_2d_array[$i,$j]} ] #current value is calculated directly
        then
            printf ${data_source[${directories_2d_array[$i,$j]}]} #print value for directory in current place in 2d array
        elif [ $j != 0 ] && [ ! -z ${directories_2d_array[$i,$(($j-1))]} ] #there's anything in parent directory (above)
        then
            sum_in_this_dir_children=0
            forward_iterator=$(( $i + 1 ))
            while [ -z ${directories_2d_array[$forward_iterator,$(($j-1))]} ] && [ $forward_iterator -lt ${#directories_2d_array[@]} ] #loop through any possible children of current directory until reach end of 2d array
            do
                if [ ! -z ${directories_2d_array[$forward_iterator,$j]} ] #any child containing value
                then
                    sum_in_this_dir_children=$(( $sum_in_this_dir_children + ${data_source[${directories_2d_array[$forward_iterator,$j]}]} )) #aggregate sum
                fi

                forward_iterator=$(( $forward_iterator + 1 ))
            done

            current_value=$(( ${data_source[${directories_2d_array[$i,$(($j-1))]}]} - $sum_in_this_dir_children ))

            if [ $current_value -gt 0 ] #anything in this directory
            then
                next_level="${directories_2d_array[$i,$(($j-1))]}-${j}" #create some key for cell in row below
                directories_2d_array[$i,$j]=$next_level #assign fake key so it appears in loop through row below
                data_source[$next_level]=$current_value #assign value to fake key so it it used in loop through row below
            fi

            printf $current_value
        fi
        
        printf '\t'
    done

    echo ''
done

#git log --format=format: --name-only | egrep -v '^$' | sort | uniq -c | sort -r | head -5

#todo: srednia ilosc autorów 1 pliku
