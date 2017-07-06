#!/usr/bin/env bash

echo "Implementation, Reading 10 Elements, Writing 100 Elements, Writing/Reading1000 Elements" > ../results/data.csv

echo -n "Implementation, " >  header.csv

cd youpi/requests/

for test in write/*.rq; do echo  -n $test", "   ; done >> ../../header.csv

for test in read/*.rq; do echo  -n $test", "   ; done >>  ../../header.csv

for test in time/*.rq; do echo  -n $test", "   ; done >> ../../header.csv

cd ../../

cat header.csv | sed 's/..$//'  > ../results/data.csv

echo "" >> ../results/data.csv

for report in report/*; do cat $report >> ../results/data.csv; done

cd ../results/

git add data.csv

TIME=`date`

MESSAGE="Results updated at "$TIME

git commit -m "$MESSAGE"

git push
