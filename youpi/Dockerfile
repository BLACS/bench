FROM ocaml/opam
RUN sudo apt-get update && sudo apt-get install -y  iptables init-system-helpers libapparmor1 libc6 libdevmapper1.02.1 libltdl7 libseccomp2 && \
 curl -O https://download.docker.com/linux/debian/dists/stretch/pool/stable/amd64/docker-ce_17.06.0~ce-0~debian_amd64.deb && sudo dpkg -i docker-ce_17.06.0~ce-0~debian_amd64.deb
RUN sudo adduser opam docker
RUN sudo apt-get update && opam update && opam depext -i -y ocurl ounit ppx_deriving_yojson
COPY . bench
RUN sudo chown -R opam:opam bench/
WORKDIR bench
RUN eval `opam config env` && make
ENTRYPOINT ["./youpi"]