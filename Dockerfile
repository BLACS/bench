FROM ubuntu:latest
RUN git clone https://github.com/BLACS/bench.git
RUN cd bench
RUN make
CMD ["./check.sh"]