#!/bin/bash

FILE=$1

cat $FILE | awk '{ if ( $4 < 0.5 ) {printf("%s    %15.9f   %15.9f    %15.9f    1    1    1 \n",$1,$2,$3,$4+0.5)} else {printf("%s    %15.9f   %15.9f    %15.9f    1    1    1 \n",$1,$2,$3,$4-1+0.5)} }' > POS.center.reduced.q
