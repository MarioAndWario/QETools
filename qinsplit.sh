#!/bin/bash
#This script will split the QE input file "QE.in"
#into seperate files: IN.q, CELL.q, POT.q, POS.q, KP.q
linenum1=$(grep -n "/" QE.in | tail -n 1 | awk -F ":" '{print $1}')
sed -n "1,$linenum1 p" QE.in > IN.q
linenum2=$(grep -n "CELL_PARAMETERS" QE.in | tail -n 1 | awk -F ":" '{print $1}')
sed -n "$linenum2,$(echo $linenum2+3 | bc) p" QE.in > CELL.q
linenum3=$(grep -n "ATOMIC_SPECIES" QE.in | tail -n 1 | awk -F ":" '{print $1}')
linenum4=$(grep -n "ATOMIC_POSITIONS" QE.in | tail -n 1 | awk -F ":" '{print $1}')
linenum5=$(grep -n "K_POINTS" QE.in | tail -n 1 | awk -F ":" '{print $1}')
sed -n "$linenum3,$(echo $linenum4-1 | bc) p" QE.in > POT.q
sed -n "$linenum4,$(echo $linenum5-1 | bc) p" QE.in > POS.q
sed -n "$linenum5,$ p" QE.in > KP.q