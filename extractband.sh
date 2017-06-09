#!/bin/bash

############################################################
# This script will extract bands from eqp1.dat and arrange
# the data into Mathematica form
# Author: Meng Wu
# Date: 20170210
############################################################

EQPFile="eqp1.dat"

KListFile="KList.dat"
BandDataMFFile="BandData.MF.dat"
BandDataQPFile="BandData.QP.dat"

rm -rf ${KListFile}
rm -rf ${BandDataMFFile}
rm -rf ${BandDataQPFile}

# Number of kpoints
# Number of bands for each kpoint

NumofBands=$(sed -n '1p' $EQPFile | awk '{print $4}')

echo "================================================="

echo "Number of bands for each kpoint : ${NumofBands}"

NumofLines=$(wc -l $EQPFile | awk '{print $1}')

echo "Number of Lines : ${NumofLines}"

NumofKpts=$(echo ${NumofLines} ${NumofBands} | awk '{print $1/($2+1)}')

echo "Number of kpoints : ${NumofKpts}"

for ((ik=1;ik<=${NumofKpts};ik++))
do
    kptline=$(echo $ik $NumofBands | awk '{print ($1-1)*($2+1)+1}')
    eqpline_start=$(echo $kptline | awk '{print $1+1}')
    eqpline_end=$(echo $kptline $NumofBands | awk '{print $1+$2}')

    sed -n "$kptline p" $EQPFile | awk '{printf("%15.10f  %15.10f  %15.10f \n",$1,$2,$3) }' >> ${KListFile}

    sed -n "$eqpline_start, $eqpline_end p" $EQPFile | awk '{printf("%17.9f \n", $3)}' >> ${BandDataMFFile}

    sed -n "$eqpline_start, $eqpline_end p" $EQPFile | awk '{printf("%17.9f \n", $4)}' >> ${BandDataQPFile}
done

echo "================================================="
