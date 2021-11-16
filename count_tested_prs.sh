#!/bin/bash

echo 0 100 200 300 400 500 | tr " " "\n" | xargs -I{} sh -c "git log --merges --skip={} --max-count=1 --first-parent -m --pretty=format:'%cs %h ' ; git log --merges --skip={} --max-count=100 --name-only --first-parent -m --oneline --pretty=format:'' | sed -z 's/\n/\t/g;s/\t\t/\n/g' | grep -c 'Test'"
