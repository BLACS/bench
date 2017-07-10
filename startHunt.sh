#!/usr/bin/env bash

git clone git@github.com:BLACS/youpi.git
cd youpi
cd ..
ocamlbuild -clean
ocamlbuild -use-ocamlfind hunt.native
mkdir report; mr up
./hunt.native &
