CONTRIB=$1
URL=$2
REPORT=$CONTRIB.csv
echo $CONTRIB
echo $CONTRIB > $REPORT
docker build -t youpi .
docker run -t --rm --name youpi-$CONTRIB youpi $URL $CONTRIB > ../report/$REPORT
