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
# ------
#Version: 1.0
#Date: Feb. 14, 2017
# ------
#Version: 2.0
#Date: Nov. 30, 2017
#Add support for "crystal_b" kpath
######################### Variables ###########################

version='2.0'
QEINPUT="QE.in"
QEOUTPUT="QE.out"
INFILE="QE.out"
KPTFILE="Klength.dat"
EIGSHIFTFILE="Eig.shift.dat"
EIGFILE_UP="eqp.mf.up.dat"
TEMPEIGFILE_UP="tempEig.up.dat"
EIGFILE_DOWN="eqp.mf.down.dat"
TEMPEIGFILE_DOWN="tempEig.down.dat"
EIGFILE_MERGE="eqp.mf.up+down.dat"
TEMPEIGFILE_MERGE="tempEig.up+down.dat"
TEMPEIGFILE_MERGE_="tempEig0.up+down.dat"
BANDSFILE="eigenvalue"
BANDSSHIFTFILE="eigenvalue.shift"
FERMIENERGYFILE="../nscf/QE.out"
Helper1="helper1.dat"
Helper2="helper2.dat"

TEMPkp="KP.temp.q"

#####################
# write bands with indices [BandStart, BandEnd] into eqp.dat form
BandStart=1
BandEnd=320

BandStart_MERGE=1
BandEnd_MERGE=640

NumofEQPBands=$( echo "${BandEnd}-${BandStart}+1" | bc )
NumofEQPBands_MERGE=$( echo "${BandEnd_MERGE}-${BandStart_MERGE}+1" | bc )


echo "BandStart = ${BandStart} BandEnd = ${BandEnd} NumofEQPBands = ${NumofEQPBands} NumofEQPBands_MERGE = ${NumofEQPBands_MERGE}"

echo "========================================================"
echo "====================qouteig_eqp.sh V.$version===================="
echo "========================================================"

#length unit in QE
if [ -z $1 ]; then
    alat=$(grep -a --text 'alat' ${QEOUTPUT} | head -1 | awk '{print $5}' )
    bohrradius=0.52917721092
    transconstant=$(echo $alat $bohrradius | awk '{print $1*$2}')
    #   echo "alat is $transconstant Angstrom"
else
    transconstant=$1
    #   echo "alat is $transconstant Angstrom"
fi

###############################################################
#######################  File clearance  ######################
if [ -f $KPTFILE ]; then
    rm -f $KPTFILE
fi

if [ -f $EIGFILE_UP ]; then
    rm -f $EIGFILE_UP
fi

if [ -f $TEMPEIGFILE_UP ]; then
    rm -f $TEMPEIGFILE_UP
fi

if [ -f $EIGFILE_DOWN ]; then
    rm -f $EIGFILE_DOWN
fi

if [ -f $TEMPEIGFILE_DOWN ]; then
    rm -f $TEMPEIGFILE_DOWN
fi
if [ -f $EIGFILE_MERGE ]; then
    rm -f $EIGFILE_MERGE
fi

if [ -f $TEMPEIGFILE_MERGE ]; then
    rm -f $TEMPEIGFILE_MERGE
fi

if [ -f $TEMPEIGFILE_MERGE_ ]; then
    rm -f $TEMPEIGFILE_MERGE_
fi

if [ -f $BANDSFILE ]; then
    rm -f $BANDSFILE
fi

if [ -f $Helper1 ]; then
    rm -f $Helper1
fi

if [ -f $Helper2 ]; then
    rm -f $Helper2
fi

if [ -f $TEMPkp ]; then
    rm -f $TEMPkp
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
# FlagNSpin=$(grep -a --text 'nspin' $QEINPUT | awk -F "=" '{print $2}' | awk '{print $1}')
# #echo ${FlagNSpin}
# if [ $FlagNSpin -eq 1 ]; then
#     echo "We are doing non-magnetic calculation: nspin = $FlagNSpin"
#     VBMindex=$(echo $numofelec | awk '{print int($1/2)}')
# elif [ $FlagNSpin -eq 2 ]; then
#     echo "We are doing collinear calculation: nspin = $FlagNSpin"
#     VBMindex=$(echo $numofelec | awk '{print int($1)}')
# elif [ $FlagNSpin -eq 4 ]; then
#     echo "We are doing non-collinear calculation: nspin = $FlagNSpin"
#     VBMindex=$(echo $numofelec | awk '{print int($1)}')
# else
#     echo "Error about nspin"
#     exit 1
# fi

# echo "Index of VBM = $VBMindex"

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

if [ -z $kptstartline2 ]; then
   echo ">>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>"
   echo "You are not doing a band structure calculations, check your IN.q!"
   exit 123
fi

#!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!
#numofkpts=2
for ((i=1;i<=$numofkpts;i++))
do
    kptline=$(echo $i $kptstartline | awk '{print $2+($1-1)}')

    if [ $(echo "$i%100" | bc) == "0" ]; then
        echo "ik = ${i}"
    fi
    
    #!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!
    eigstartline=$(echo $numoflines $i $kptstartline2 | awk '{print $3+2+($1+3)*($2-1)}')
    #echo $eigstartline
    eigendline=$(echo $eigstartline $numoflines | awk '{print $1+$2}')
    #echo $eigendline
    #!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!

    for ((j=$eigstartline;j<$eigendline+1;j++))
    do
        echo -n -e "$(sed -n "$j p" $INFILE)" >> $TEMPEIGFILE_UP
    done

    echo -e "" >> $TEMPEIGFILE_UP
    
done

##################
## Spin UP states
echo " <<<< Spin DOWN bands >>>>"
###############################################################
#####################Loop over kpoints#########################
#Take special notice of HiSymCounter=2, which is the first one
kptstartline2=$(grep -a --text -n 'SPIN DOWN' $QEOUTPUT | awk -F ":" '{print $1+3}')
kptstartline=$(grep -a --text -n 'number of k points=' $QEOUTPUT | awk -F ":" '{print $1}'| awk '{print $1+2}')

if [ -z $kptstartline2 ]; then
   echo ">>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>"
   echo "You are not doing a band structure calculations, check your IN.q!"
   exit 123
fi

#!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!
for ((i=1;i<=$numofkpts;i++))
do
    kptline=$(echo $i $kptstartline | awk '{print $2+($1-1)}')

    if [ $(echo "$i%100" | bc) == "0" ]; then
        echo "ik = ${i}"
    fi
    
    #!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!
    eigstartline=$(echo $numoflines $i $kptstartline2 | awk '{print $3+2+($1+3)*($2-1)}')
    #echo $eigstartline
    eigendline=$(echo $eigstartline $numoflines | awk '{print $1+$2}')
    #echo $eigendline
    #!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!

    for ((j=$eigstartline;j<$eigendline+1;j++))
    do
        echo -n -e "$(sed -n "$j p" $INFILE)" >> $TEMPEIGFILE_DOWN
    done

    echo -e "" >> $TEMPEIGFILE_DOWN
    
done

####################################################################
# Combine up and down bands and sort up the band energies
paste $TEMPEIGFILE_UP $TEMPEIGFILE_DOWN > $TEMPEIGFILE_MERGE_
for ((i=1;i<=$numofkpts;i++))
do
    if [ $(echo "$i%100" | bc) == "0" ]; then
        echo "ik = ${i}"
    fi
    sed -n "${i} p" $TEMPEIGFILE_MERGE_ | awk ' {split( $0, a, " "); asort( a ); for( i = 1; i <= length(a); i++ ) printf( "%s ", a[i]); printf( "\n" ); } ' >> $TEMPEIGFILE_MERGE
done

####################################################################
KPstartline=$(grep -n ' cryst. coord.' ./QE.out | awk -F ":" '{print $1+1}')
KPendline=$(echo "${KPstartline} + ${numofkpts} - 1" | bc)

echo "KPstartline = $KPstartline, KPendline = $KPendline"

sed -n "${KPstartline}, ${KPendline} p" ${QEOUTPUT} | awk -F ")," '{print $1}' | awk '{printf("%10.7f  %10.7f  %10.7f \n",$5,$6,$7)}' > ${TEMPkp}

flag_kp=$(sed -n "1p" KP.q | awk '{print $2}')

echo "flag_kp = ${flag_kp}"

if [ ${flag_kp} == "crystal" ]; then
    echo " ====== We will use kpoints in KP.q file! ====== "
    for ((i=1;i<=$numofkpts;i++))
    do
        # kptline in KP.q
        kptline=$(echo $i | awk '{print ($1+2)}')
        sed -n "${kptline} p" KP.q | awk -v numband=${NumofEQPBands} '{printf("%14.9f  %14.9f  %14.9f %7d \n",$1, $2, $3, numband)}' >> $EIGFILE_UP

        sed -n "${kptline} p" KP.q | awk -v numband=${NumofEQPBands} '{printf("%14.9f  %14.9f  %14.9f %7d \n",$1, $2, $3, numband)}' >> $EIGFILE_DOWN

        sed -n "${kptline} p" KP.q | awk -v numband=${NumofEQPBands_MERGE} '{printf("%14.9f  %14.9f  %14.9f %7d \n",$1, $2, $3, numband)}' >> $EIGFILE_MERGE

        sed -n "${i} p" ${TEMPEIGFILE_UP} | awk -v bandstart=${BandStart} -v bandend=${BandEnd} '{for (i=bandstart;i<=bandend;i++) printf("%8d %8d %16.9f \n",1,i,$i) }' >> $EIGFILE_UP

        sed -n "${i} p" ${TEMPEIGFILE_DOWN} | awk -v bandstart=${BandStart} -v bandend=${BandEnd} '{for (i=bandstart;i<=bandend;i++) printf("%8d %8d %16.9f \n",1,i,$i) }' >> $EIGFILE_DOWN

        sed -n "${i} p" ${TEMPEIGFILE_MERGE} | awk -v bandstart=${BandStart_MERGE} -v bandend=${BandEnd_MERGE} '{for (i=bandstart;i<=bandend;i++) printf("%8d %8d %16.9f \n",1,i,$i) }' >> $EIGFILE_MERGE

    done
else
    echo " ====== We will use kpoints in QE.out file! ====== "
    for ((i=1;i<=$numofkpts;i++))
    do
        # kptline in KP.temp.q
        kptline=$(echo $i | awk '{print ($1)}')
        #echo "kptline = $kptline"
        sed -n "${kptline} p" ${TEMPkp} | awk -v numband=${NumofEQPBands} '{printf("%14.9f  %14.9f  %14.9f %7d \n",$1, $2, $3, numband)}' >> $EIGFILE_UP

        sed -n "${kptline} p" ${TEMPkp} | awk -v numband=${NumofEQPBands} '{printf("%14.9f  %14.9f  %14.9f %7d \n",$1, $2, $3, numband)}' >> $EIGFILE_DOWN

        sed -n "${kptline} p" ${TEMPkp} | awk -v numband=${NumofEQPBands_MERGE} '{printf("%14.9f  %14.9f  %14.9f %7d \n",$1, $2, $3, numband)}' >> $EIGFILE_MERGE

        sed -n "${i} p" ${TEMPEIGFILE_UP} | awk -v bandstart=${BandStart} -v bandend=${BandEnd} '{for (i=bandstart;i<=bandend;i++) printf("%8d %8d %16.9f \n",1,i,$i) }' >> $EIGFILE_UP

        sed -n "${i} p" ${TEMPEIGFILE_DOWN} | awk -v bandstart=${BandStart} -v bandend=${BandEnd} '{for (i=bandstart;i<=bandend;i++) printf("%8d %8d %16.9f \n",1,i,$i) }' >> $EIGFILE_DOWN

        sed -n "${i} p" ${TEMPEIGFILE_MERGE} | awk -v bandstart=${BandStart_MERGE} -v bandend=${BandEnd_MERGE} '{for (i=bandstart;i<=bandend;i++) printf("%8d %8d %16.9f \n",1,i,$i) }' >> $EIGFILE_MERGE
    done
fi

################################################################
echo "=======================Finished!========================"
