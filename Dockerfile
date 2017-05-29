FROM ubuntu
RUN apt-get update && apt-get install -y \
    make
COPY . ./bench
WORKDIR bench
RUN make
ENTRYPOINT ./check.sh