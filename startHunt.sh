#!/usr/bin/env bash

ocamlbuild -clean
ocamlbuild -use-ocamlfind hunt.native
mkdir report; mr up
./hunt.native &
