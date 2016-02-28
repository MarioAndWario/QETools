#!/bin/bash
Infile="POS.q"
C_ori=15.0
C_final=20.0
rm -rf POS.${C_ori}.to.${C_final}.q
sed -n '1 p' ${Infile} > POS.${C_ori}.to.${C_final}.q
sed -n '2,$ p' ${Infile} | awk -v C_ori=${C_ori} -v C_final=${C_final} '{printf "%s  %12.9f  %12.9f  %12.9f  %i  %i  %i \n",$1, $2, $3, $4*C_ori/C_final, $5, $6, $7}' >> POS.${C_ori}.to.${C_final}.q