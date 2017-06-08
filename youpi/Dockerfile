FROM ocaml/opam
RUN sudo apt-get update && opam update && opam depext -i -y ocurl ounit ppx_deriving_yojson
COPY . bench
RUN sudo chown -R opam:opam bench/
WORKDIR bench
RUN eval `opam config env` && make
ENTRYPOINT ["./youpi"]