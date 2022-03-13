#!/bin/bash

# define variables
YEAR=2022
MONTH_ALPHA=february
MONTH=2
DAY=13
VERSION=1.2

REGEX="s|\\\\YEAR|${YEAR}|g;s|\\\\MONTH_ALPHA|${MONTH_ALPHA}|g;s|\\\\MONTH|${MONTH}|g;s|\\\\DAY|${DAY}|g;s|\\\\VERSION|${VERSION}|g"

# write variables into files
sed $REGEX kanbun-proto.tex > kanbun.tex
sed $REGEX kanbun-proto.sty > kanbun.sty
