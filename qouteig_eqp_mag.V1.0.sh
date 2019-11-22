#!/bin/bash
###############################################################
####################### Descriptions ##########################
#This script read in the "QE.out" file generated from pw.x
#and arrange the eigenvalues in the output file "eigenvalue",
#we also read in the kpoints in "bands.dat" file, calculate the
#length of kpath, and output in the "eigenvalue" file. You can
#use the date in "eigenvalue" file to plot bandstructures
###############################################################
#Author: Meng Wu, Ph.D. Candidate in Physics
#Affiliation: University of California, Berkeley
#Version: 1.0
#Date: Aug. 31, 2015
# ------
#Verison: 2.0
#Date: Jul. 09, 2016
# ------
#Version: 3.0
#Date: Oct. 31, 2016
# ------
#Version: 4.0
#Date: May. 30, 2017
# ------
#Version: 5.0
#Data: Nov. 02, 2017
#Description: Add support for nspin=2 calculations
# -------
#Now klength units is absolute (1/Angstrom), previous version is (1/Angstrom)/(2*pi)
######################### Variables ###########################
version='4.0'
QEINPUT="QE.in"
QEOUTPUT="QE.out"
INFILE="QE.out"

KPTFILE_up="Klength.up.dat"
KPTFILE_down="Klength.down.dat"

EIGFILE_up="eqp.up.dat"
EIGFILE_down="eqp.down.dat"

TEMPEIGFILE_up="tempEig.up.dat"
TEMPEIGFILE_down="tempEig.down.dat"

FERMIENERGYFILE="../nscf/QE.out"
Helper1="helper1.dat"
Helper2="helper2.dat"

#####################
# write bands with indices [BandStart, BandEnd] into eqp.dat form
BandStart=26 # 29-38
BandEnd=41 # 39-42

NumofEQPBands=$( echo "${BandEnd}-${BandStart}+1" | bc )

EQPoutputFile="eqp.mf.dat"

echo "BandStart = ${BandStart} BandEnd = ${BandEnd} NumofEQPBands = ${NumofEQPBands}"

echo "========================================================"
echo "====================qouteig_eqp_mag.sh V.$version===================="
echo "========================================================"
#length unit in QE
if [ -z $1 ]; then
    alat=$(grep -a --text 'alat)  =' ${QEOUTPUT} | head -1 | awk '{print $5}' )
    bohrradius=0.52917721092
    # transconstant=$(echo $alat $bohrradius | awk '{print $1*$2}')
    transconstant=$(echo $alat $bohrradius | awk '{print $1*$2/2.0/3.14159265359}')

    echo "alat = $alat"
    #   echo "alat is $transconstant Angstrom"
else
    transconstant=$1
    #   echo "alat is $transconstant Angstrom"
fi

echo "transconstant = $transconstant"

###############################################################
#######################  File clearance  ######################
if [ -f $EIGFILE_up ]; then
    rm -f $EIGFILE_up
fi

if [ -f $EIGFILE_down ]; then
    rm -f $EIGFILE_down
fi

if [ -f $KPTFILE ]; then
    rm -f $KPTFILE
fi

if [ -f $TEMPEIGFILE_up ]; then
    rm -f $TEMPEIGFILE_up
fi

if [ -f $TEMPEIGFILE_down ]; then
    rm -f $TEMPEIGFILE_down
fi

if [ -f $EQPoutputFile ]; then
    rm -f $EQPoutputFile
fi


###############################################################
#Find the fermi energy from a previous nscf calculation
if [ -d $FERMIENERGYFILE ]; then
    echo "Reading Fermi level from ../nscf/QE.out ..."
    if [ ! -z $(grep -a --text "Fermi" $FERMIENERGYFILE) ];then
        EFermi=$(grep -a --text "Fermi" $FERMIENERGYFILE | awk '{print $5}')
        echo "Find Fermi energy: Ef = $EFermi "
    else
        echo "Cannot find Fermi energy:"
        echo "Maybe you use \"fixed\" occupation or your calculation failed"
    fi
else
    echo "Cannot find ../nscf/QE.out"
    echo "Set Ef = 0"
    EFermi=0
fi
###############################################################
echo "========================================================"
echo "========================================================"
numofelec=$(grep -a --text "number of electrons" $QEOUTPUT | awk -F "=" '{print int($2)}')
############### See if non-colin ##################
FlagNSpin=$(grep -a --text 'nspin' $QEINPUT | awk -F "=" '{print $2}' | awk -F "," '{print $1}' | awk '{print $1}')
#echo ${FlagNSpin}
if [ $FlagNSpin -eq 1 ]; then
    echo "We are doing non-magnetic calculation: nspin = $FlagNSpin"
    VBMindex=$(echo $numofelec | awk '{print int($1/2)}')
elif [ $FlagNSpin -eq 2 ]; then
    echo "We are doing collinear calculation: nspin = $FlagNSpin"
    VBMindex=$(echo $numofelec | awk '{print int($1/2)}')
elif [ $FlagNSpin -eq 4 ]; then
    echo "We are doing non-collinear calculation: nspin = $FlagNSpin"
    VBMindex=$(echo $numofelec | awk '{print int($1)}')
else
    echo "Error about nspin"
    exit 1
fi

echo "Index of VBM = $VBMindex"

###############################################################
#Find "reciprocal axes in cartesian coordinates" module and read the starting point for each segment
#cat $QEOUTPUT | tr -d '\000'
b1x=$(grep -a --text "b(1)" $QEOUTPUT | awk '{print $4}')
b1y=$(grep -a --text "b(1)" $QEOUTPUT | awk '{print $5}')
b1z=$(grep -a --text "b(1)" $QEOUTPUT | awk '{print $6}')
b2x=$(grep -a --text "b(2)" $QEOUTPUT | awk '{print $4}')
b2y=$(grep -a --text "b(2)" $QEOUTPUT | awk '{print $5}')
b2z=$(grep -a --text "b(2)" $QEOUTPUT | awk '{print $6}')
b3x=$(grep -a --text "b(3)" $QEOUTPUT | awk '{print $4}')
b3y=$(grep -a --text "b(3)" $QEOUTPUT | awk '{print $5}')
b3z=$(grep -a --text "b(3)" $QEOUTPUT | awk '{print $6}')
#echo "b1 = ($b1x, $b1y, $b1z)"
#echo "b2 = ($b2x, $b2y, $b2z)"
#echo "b3 = ($b3x, $b3y, $b3z)"
###############################################################
#Find high-symmetry points from $QEINPUT and convert it into cartesian coordinates
NumHiSymP=$(grep -a --text -A 1 "K_POINTS" $QEINPUT | tail -1 | awk '{print $1}')
#it is actually the first High Symmetry Point
HiSymCounter=2
FlagChangeStartingPoint=1
BaseLength=0.0
KLength=0
###############################################################
#!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!
#numofbnds=$(sed -n '1p' $INFILE | awk '{print $3}' | awk -F"," '{print $1}' )
numofbnds=$(grep -a --text 'number of Kohn-Sham states' $QEOUTPUT | awk -F "=" '{print $2}'| awk '{print $1}')
#numofkpts=$(sed -n '1p' $INFILE | awk '{print $5}')
numofkpts=$(grep -a --text 'number of k points=' $QEOUTPUT | awk -F "=" '{print $2}' | awk '{print $1}')
#!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!
echo "========================================================"
echo "number of kpoints = $numofkpts, number of bands per spin = $numofbnds"
#if numofbnds is undividable by 10
#!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!
#In QE.out, there are 8 bands in a line
#In bands.dat, there are 10 bands in a line
bandsperline=8
numoflines=$(echo $numofbnds $bandsperline | awk '{print int(($1+$2-1)/$2)}')
#!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!
echo "numoflines = $numoflines"

##################
## Spin UP states
echo " <<<< Spin UP bands >>>>"
###############################################################
#####################Loop over kpoints#########################
#Take special notice of HiSymCounter=2, which is the first one
kptstartline2=$(grep -a --text -n 'SPIN UP' $QEOUTPUT | awk -F ":" '{print $1+3}')

kptstartline=$(grep -a --text -n 'number of k points=' $QEOUTPUT | awk -F ":" '{print $1}'| awk '{print $1+2}')

#echo "kptstartline2 = $kptstartline2"

if [ -z $kptstartline2 ]; then
    echo ">>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>"
    echo "You are not doing a band structure calculations, check your IN.q!"
    exit 123
fi

#echo "kptstartline = $kptstartline"
#!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!
for ((i=1;i<=$numofkpts;i++))
do
    if [ $(echo "$i%100" | bc) == "0" ]; then
        echo "ik = ${i}"
    fi
    kptline=$(echo $i $kptstartline | awk '{print $2+($1-1)}')

    #!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!
    eigstartline=$(echo $numoflines $i $kptstartline2 | awk '{print $3+2+($1+3)*($2-1)}')
    #echo $eigstartline
    eigendline=$(echo $eigstartline $numoflines | awk '{print $1+$2}')
    #echo $eigendline
    #!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!

    for ((j=$eigstartline;j<$eigendline+1;j++))
    do
        echo -n -e "$(sed -n "$j p" $INFILE)" >> ${TEMPEIGFILE_up}
    done
    echo -e "" >> ${TEMPEIGFILE_up}

done

for ((i=1;i<=$numofkpts;i++))
do
    # kptline in KP.q
    kptline=$(echo $i | awk '{print ($1+2)}')
    sed -n "${kptline} p" KP.q | awk -v numband=${NumofEQPBands} '{printf("%14.9f  %14.9f  %14.9f %7d \n",$1, $2, $3, numband)}' >> ${EIGFILE_up}

    sed -n "${i} p" ${TEMPEIGFILE_up} | awk -v bandstart=${BandStart} -v bandend=${BandEnd} '{for (i=bandstart;i<=bandend;i++) printf("%8d %8d %16.9f \n",1,i,$i) }' >> ${EIGFILE_up}
done

#rm -rf ${TEMPEIGFILE_up}

##################
## Spin DOWN states
echo " <<<< Spin DOWN bands >>>>"
HiSymCounter=2
FlagChangeStartingPoint=1
KLength=0
###############################################################
#####################Loop over kpoints#########################
#Take special notice of HiSymCounter=2, which is the first one
kptstartline2=$(grep -a --text -n 'SPIN DOWN' $QEOUTPUT | awk -F ":" '{print $1+3}')

kptstartline=$(grep -a --text -n 'number of k points=' $QEOUTPUT | awk -F ":" '{print $1}'| awk '{print $1+2}')

#echo "kptstartline2 = $kptstartline2"

if [ -z $kptstartline2 ]; then
    echo ">>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>"
    echo "You are not doing a band structure calculations, check your IN.q!"
    exit 123
fi

#echo "kptstartline = $kptstartline"
#!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!
for ((i=1;i<=$numofkpts;i++))
do
    if [ $(echo "$i%100" | bc) == "0" ]; then
        echo "ik = ${i}"
    fi

    kptline=$(echo $i $kptstartline | awk '{print $2+($1-1)}')

    #!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!
    eigstartline=$(echo $numoflines $i $kptstartline2 | awk '{print $3+2+($1+3)*($2-1)}')
    #echo $eigstartline
    eigendline=$(echo $eigstartline $numoflines | awk '{print $1+$2}')
    #echo $eigendline
    #!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!

    for ((j=$eigstartline;j<$eigendline+1;j++))
    do
        echo -n -e "$(sed -n "$j p" $INFILE)" >> ${TEMPEIGFILE_down}
    done
    echo -e "" >> ${TEMPEIGFILE_down}

done

for ((i=1;i<=$numofkpts;i++))
do
    # kptline in KP.q
    kptline=$(echo $i | awk '{print ($1+2)}')
    sed -n "${kptline} p" KP.q | awk -v numband=${NumofEQPBands} '{printf("%14.9f  %14.9f  %14.9f %7d \n",$1, $2, $3, numband)}' >> ${EIGFILE_down}

    sed -n "${i} p" ${TEMPEIGFILE_down} | awk -v bandstart=${BandStart} -v bandend=${BandEnd} '{for (i=bandstart;i<=bandend;i++) printf("%8d %8d %16.9f \n",2,i,$i) }' >> ${EIGFILE_down}
done

# rm -rf ${TEMPEIGFILE_down}

echo "Combining two spins"

echo "================ For ${EQPFILE_up}  ===================="
NumofBands_1=$(sed -n '1p' ${EIGFILE_up} | awk '{print $4}')

NumofLines_1=$(wc -l $EIGFILE_up | awk '{print $1}')

#echo "Number of Lines : ${NumofLines}"

NumofKpts_1=$(echo ${NumofLines_1} ${NumofBands_1} | awk '{print $1/($2+1)}')

echo "Number of bands for each kpoint : ${NumofBands_1}"
echo "Number of kpoints : ${NumofKpts_1}"

echo "================ For ${EIGFILE_down}  ===================="
NumofBands_2=$(sed -n '1p' $EIGFILE_down | awk '{print $4}')

NumofLines_2=$(wc -l $EIGFILE_down | awk '{print $1}')

#echo "Number of Lines : ${NumofLines}"

NumofKpts_2=$(echo ${NumofLines_2} ${NumofBands_2} | awk '{print $1/($2+1)}')

echo "Number of bands for each kpoint : ${NumofBands_2}"
echo "Number of kpoints : ${NumofKpts_2}"

echo "================================================="

NumofTotalBands=$(echo "${NumofBands_1} + ${NumofBands_2}" | bc)

echo "Total number of bands : ${NumofTotalBands}"

if [ ${NumofKpts_2} != ${NumofKpts_1} ]; then
   echo "NumofKpts mismatch!"
   exit 1
fi

#for ((ik=1;ik<=2;ik++))
for ((ik=1;ik<=${NumofKpts_1};ik++))
do
    echo "ik = ${ik}"
    kptline_1=$(echo $ik $NumofBands_1 | awk '{print ($1-1)*($2+1)+1}')
    eqpline_start_1=$(echo $kptline_1 | awk '{print $1+1}')
    eqpline_end_1=$(echo $kptline_1 $NumofBands_1 | awk '{print $1+$2}')

    kptline_2=$(echo $ik $NumofBands_2 | awk '{print ($1-1)*($2+1)+1}')
    eqpline_start_2=$(echo $kptline_2 | awk '{print $1+1}')
    eqpline_end_2=$(echo $kptline_2 $NumofBands_2 | awk '{print $1+$2}')

    sed -n "${kptline_1} p" $EIGFILE_up
    sed -n "${kptline_2} p" $EIGFILE_down

    sed -n "${kptline_1} p" $EIGFILE_up | awk -v TotBnd="${NumofTotalBands}" '{printf("%17.9f %17.9f %17.9f  %8d \n",$1,$2,$3,TotBnd)}' >> ${EQPoutputFile}
    sed -n "${eqpline_start_1}, ${eqpline_end_1} p" $EIGFILE_up >> ${EQPoutputFile}
    sed -n "${eqpline_start_2}, ${eqpline_end_2} p" $EIGFILE_down >> ${EQPoutputFile}

done


################################################################
echo "=======================Finished!========================"
