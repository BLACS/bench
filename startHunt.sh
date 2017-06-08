#!/usr/bin/env bash

ocamlbuild -clean
ocamlbuild -use-ocamlfind hunt.native
mr up
./hunt.byte &
