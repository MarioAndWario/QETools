#!/bin/bash
###############################################################
####################### Descriptions ##########################
# This script reads in spin.*.dat produced by spinor_pw2bgw.x
# and eqp.dat output by qouteig_eqp.dat or BGW, and then it will
# combine these two files to get a new eqp.spin.dat with the last
# two columnes corresponding to spin polarization along one direction
###############################################################
#Author: Meng Wu, Ph.D. Candidate in Physics
#Affiliation: University of California, Berkeley
# ------
#Version: 1.0
#Date: Nov. 30, 2017
######################### Variables ###########################

version='1.0'
QEINPUT="QE.in"
QEOUTPUT="QE.out"
INFILE="QE.out"

EIGFILE="eqp.mf.dat"

SPINFILE="spin.z.dat"
TEMPspinout="temp.spin.dat"

EQPSPINFILE="eqp.${SPINFILE}"

###############################################################
#!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!
#numofbnds=$(sed -n '1p' $INFILE | awk '{print $3}' | awk -F"," '{print $1}' )
numofbnds=$(grep -a --text 'number of Kohn-Sham states' $QEOUTPUT | awk -F "=" '{print $2}'| awk '{print $1}')
#numofkpts=$(sed -n '1p' $INFILE | awk '{print $5}')
numofkpts=$(grep -a --text 'number of k points=' $QEOUTPUT | awk -F "=" '{print $2}' | awk '{print $1}')

NumofEQPBands=$(sed -n '1p' $EIGFILE | awk '{print $4}')

echo "================================================="

NumofLines=$(wc -l $EIGFILE | awk '{print $1}')

BandStart=$(sed -n '2p' $EIGFILE | awk '{print $2}')
endline=$(echo "$NumofEQPBands+1" | bc)
BandEnd=$(sed -n "${endline} p" $EIGFILE | awk '{print $2}')

numofkpts_=$(echo ${NumofLines} ${NumofEQPBands} | awk '{print $1/($2+1)}')
######################
# Check boundaries
if [ ${numofkpts_} -ne ${numofkpts} ]; then
    echo "[ERROR] Num of kpts mismatch!"
    exit 1
fi

if [ ${numofbnds} -le ${NumofEQPBands} ]; then
    echo "[ERROR] Num of bands from QE.out is smaller than that in eqp.dat!"
    exit 1
fi

echo "========================================================"
echo "============ arrange_bands_spin.sh V.$version ============="
echo "========================================================"

echo " We are combing ${EIGFILE} and ${SPINFILE} ! "
echo " Output : ${EQPSPINFILE}"
echo "========================================================"

######################
# Number of bands in QE.out
echo "BandStart = ${BandStart} BandEnd = ${BandEnd} NumofEQPBands = ${NumofEQPBands}"
echo "Num of kpts = ${numofkpts}, Num of bands = ${numofbnds}"
echo "========================================================"

#length unit in QE
if [ -z $1 ]; then
    alat=$(grep -a --text 'alat' ${QEOUTPUT} | head -1 | awk '{print $5}' )
    bohrradius=0.52917721092
    # transconstant=$(echo $alat $bohrradius | awk '{print $1*$2}')
    transconstant=$(echo $alat $bohrradius | awk '{print $1*$2/2.0/3.14159265359}')

    #   echo "alat is $transconstant Angstrom"
else
    transconstant=$1
    #   echo "alat is $transconstant Angstrom"
fi

###############################################################
#######################  File clearance  ######################
if [ -f $TEMPspinout ]; then
    rm -f $TEMPspinout
fi

if [ -f $EQPSPINFILE ]; then
    rm -f $EQPSPINFILE
fi

#!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!
for ((ik=1;ik<=$numofkpts;ik++))
do
    if [ $(echo "$ik%100" | bc) == "0" ]; then
        echo "ik = ${ik}"
    fi

    kptline=$(echo $ik $NumofEQPBands  | awk '{print ($2+1)*($1-1)+1}')

    echo -e " " >> $TEMPspinout
    for ((ib=$BandStart;ib<=$BandEnd;ib++))
    do
        lineinspinfile=$(echo ${ik} ${ib} ${numofbnds} | awk '{print ($1-1)*$3+$2+1}' )
        # echo "ik = ${ik} ib = ${ib} lineinspinfile=${lineinspinfile}"

        # Get the spin z component
        sed -n "${lineinspinfile} p" $SPINFILE | awk '{printf("%20.12E  %20.12E  \n",$3,$4)}' >> $TEMPspinout
    done

done

paste $EIGFILE $TEMPspinout > $EQPSPINFILE

################################################################
echo "=======================Finished!========================"
