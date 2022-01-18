#!/bin/bash

mkdir kanbun

cp kanbun.sty kanbun/kanbun.sty
cp kanbun.lua kanbun/kanbun.lua

cp README.md kanbun/README.md

cp kanbun.tex kanbun/kanbun.tex
cp kanbun-example.tex kanbun/kanbun-example.tex
cp kanbun-example.pdf kanbun/kanbun-example.pdf
cp kanbun-ja.tex kanbun/kanbun-ja.tex
cp kanbun-ja.pdf kanbun/kanbun-ja.pdf
cp kanbun-en.tex kanbun/kanbun-en.tex
cp kanbun-en.pdf kanbun/kanbun-en.pdf

zip -r -9 -X kanbun.zip kanbun

rm -r kanbun
