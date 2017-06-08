CONTRIB=$1
URL=$2
HASH=$3
REPORT=$HASH-youpi.csv
echo $CONTRIB
docker build -t youpi .
docker run -t --rm --name youpi-$CONTRIB youpi $URL > ../report/$CONTRIB/$REPORT
