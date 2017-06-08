#!/usr/bin/env bash
CONTRIB=$1
./runDocker.sh $CONTRIB
cd youpi
./runYoupi.sh
./stopDocker.sh $CONTRIB
