#!/usr/bin/env bash

echo "Implementation, Reading 10 Elements, Writing 100 Elements, Writing/Reading1000 Elements" > ../results/data.csv

for report in report/*; do cat $report >> ../results/data.csv; done

cd ../results/

git add data.csv

TIME=`date`

MESSAGE="Results updated at "$TIME

git commit -m "$MESSAGE"

git push
