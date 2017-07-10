CONTRIB=$1
URL=$2
REPORT=$CONTRIB.csv
echo $CONTRIB
docker build -t youpi .
docker run -t -v /var/run/docker.sock:/var/run/docker.sock --rm --name youpi-$CONTRIB youpi $URL $CONTRIB > ../report/$REPORT
