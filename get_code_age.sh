#!/bin/bash

i=0
file=0
timestamp=0
file_length=0
file_curly_braces_count=0
file_timestamp=0
file_max_timestamp=0

declare -A timestamp_by_dir
declare -A chars_by_dir
declare -A max_timestamp_by_dir
declare -A curly_braces_by_dir

echo 'File'$'\t''File length [chars]'$'\t''Average last modification [timestamp]'$'\t''Last modification [timestamp]'$'\t''Leading curly braces [count]'

while read line
do
    if [[ $line == *"-_-"* ]]
    then
        if [ $file_length != "0" ]
        then
            path=`echo "$line" | sed -z 's/-_-//g'`

            echo $path$'\t'$file_length$'\t'$(( $file_timestamp / $file_length ))$'\t'$file_max_timestamp$'\t'$file_curly_braces_count
            
            while [[ $path == *"/"* ]]
            do
                path=${path%/*}
                timestamp_by_dir[$path]=$((${timestamp_by_dir[$path]} + $file_timestamp))
                chars_by_dir[$path]=$((${chars_by_dir[$path]} + $file_length))
                curly_braces_by_dir[$path]=$((${curly_braces_by_dir[$path]} + $file_curly_braces_count))

                if [ -z "${max_timestamp_by_dir[$path]}" ]
                then
                    max_timestamp_by_dir[$path]=0
                fi

                max_timestamp_by_dir[$path]=$(( ${max_timestamp_by_dir[$path]} > $file_max_timestamp ? ${max_timestamp_by_dir[$path]} : $file_max_timestamp ))
            done
        fi

        i=-1
        file_length=0
        file_timestamp=0
        file_max_timestamp=0
        file_curly_braces_count=0
    elif (( i % 2 == 0 ))
    then
        timestamp="$line"
        file_max_timestamp=$(( $timestamp > $file_max_timestamp ? $timestamp : $file_max_timestamp ))
    elif (( i % 2 == 1 ))
    then
        file_length=$(( $file_length + ${#line} ))
        file_timestamp=$(( $file_timestamp + $timestamp * ${#line} ))

        if [[ `echo "$line" | tr -d ' '` == "{" ]]
        then
            file_curly_braces_count=$(( $file_curly_braces_count + 1 ))
        fi
    fi

    i=$i+1
done < <(git ls-files *.cs --exclude-standard | xargs -I{} sh -c 'git blame {} --line-porcelain ; echo -_-{}' | sed -n 's/^committer-time //p;s/^\t//p;s/^-_-/-_-/p' | sed 's/\\//g')

for path in "${!timestamp_by_dir[@]}"
do
    echo $path$'\t'${chars_by_dir[$path]}$'\t'$(( ${timestamp_by_dir[$path]} / ${chars_by_dir[$path]} ))$'\t'${max_timestamp_by_dir[$path]}$'\t'${curly_braces_by_dir[$path]}
done

#git log --format=format: --name-only | egrep -v '^$' | sort | uniq -c | sort -r | head -5

#count all curly braces
#git ls-files *.cs --exclude-standard | xargs -I{} grep '\{$' {} -c | paste -sd+ | bc

#todo: srednia ilosc autorów 1 pliku, które foldery i jak rosną, 

#it bisect start && git bisect bad && git bisect good 885350436 && git ls-files *.cs --exclude-standard | xargs -I{} grep '\{$' {} -c | paste -sd+ | bc && git bisect skip && git ls-files *.cs --exclude-standard | xargs -I{} grep '\{$' {} -c | paste -sd+ | bc && git bisect skip && git ls-files *.cs --exclude-standard | xargs -I{} grep '\{$' {} -c | paste -sd+ | bc && git bisect skip && git ls-files *.cs --exclude-standard | xargs -I{} grep '\{$' {} -c | paste -sd+ | bc && git bisect reset HEAD