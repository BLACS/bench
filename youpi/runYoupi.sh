CONTRIB=$1
URL=$2
REPORT=$CONTRIB.csv
echo $CONTRIB
docker build -t youpi .
docker run -t --rm --name youpi-$CONTRIB youpi $URL > ../report/$REPORT
