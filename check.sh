#!/usr/bin/env bash
CONTRIB=$1

docker build -t $CONTRIB contrib/$CONTRIB/

docker run -d --rm --name $CONTRIB $CONTRIB

IP=`docker inspect -f '{{range .NetworkSettings.Networks}}{{.IPAddress}}{{end}}' $CONTRIB`
IP=http://$IP

echo $IP

cd youpi

./runYoupi.sh $CONTRB $IP:8080



