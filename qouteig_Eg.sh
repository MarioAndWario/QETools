#!/bin/bash
###############################################################
####################### Descriptions ##########################
# This script read in the "QE.out" file generated from pw.x
# and determine the bandgap (indirect or direct)
# This script also support both scf and nscf/bands calculations
###############################################################
#Author: Meng Wu, Ph.D. Candidate in Physics
#Affiliation: University of California, Berkeley
# ------
#Version: 1.0
#Date: Apr. 16, 2017
# ------
#Version: 2.0
#Date: Dec. 27, 2017
# Update the FlagNspin
######################### Variables ###########################

version='1.0'
QEINPUT="QE.in"
QEOUTPUT="QE.out"
INFILE="QE.out"
KPTFILE="Klength.dat"
EIGFILE="eqp.mf.dat"
EIGSHIFTFILE="Eig.shift.dat"
TEMPEIGFILE="tempEig.dat"
BANDSFILE="eigenvalue"
BANDSSHIFTFILE="eigenvalue.shift"
FERMIENERGYFILE="../nscf/QE.out"
Helper1="helper1.dat"
Helper2="helper2.dat"

echo "========================================================"
echo "==================qouteig_Eg.sh V.$version==================="
echo "========================================================"

if [ "$#" -ne 2 ]; then
    echo "Usage: qouteig_Eg.sh BandStart BandEnd"
    exit 1
fi

#####################
# write bands with indices [BandStart, BandEnd] into eqp.dat form
BandStart=$1
BandEnd=$2

NumofEQPBands=$( echo "${BandEnd}-${BandStart}+1" | bc )

echo "BandStart = ${BandStart} BandEnd = ${BandEnd} NumofEQPBands = ${NumofEQPBands}"

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
if [ -f $EIGFILE ]; then
    rm -f $EIGFILE
fi

if [ -f $KPTFILE ]; then
    rm -f $KPTFILE
fi

if [ -f $TEMPEIGFILE ]; then
    rm -f $TEMPEIGFILE
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
FlagNSpin=$(sed -e '/\s*!.*$/d' -e '/^\s*$/d' $QEINPUT | grep -a --text 'nspin' | awk -F "=" '{print $2}' | awk '{print $1}')

echo "FlagNSpin = ${FlagNSpin}"


if [ -z $FlagNSpin ]; then
    echo "We are doing non-magnetic calculation: nspin = 1"
    VBMindex=$(echo $numofelec | awk '{print int($1/2)}')
elif [ $FlagNSpin -eq 1 ]; then
    echo "We are doing non-magnetic calculation: nspin = $FlagNSpin"
    VBMindex=$(echo $numofelec | awk '{print int($1/2)}')
elif [ $FlagNSpin -eq 2 ]; then
    echo "We are doing collinear calculation: nspin = $FlagNSpin"
    VBMindex=$(echo $numofelec | awk '{print int($1)}')
elif [ $FlagNSpin -eq 4 ]; then
    echo "We are doing non-collinear calculation: nspin = $FlagNSpin"
    VBMindex=$(echo $numofelec | awk '{print int($1)}')
else
    echo "Error about nspin"
    exit 1
fi

echo "Index of VBM = $VBMindex"

############### See if scf or nscf/bands ##################
StringCalculation=$(grep -a --text 'calculation=' $QEINPUT | awk -F "=" '{print $2}' | awk '{print $1}' | awk -F "," '{print $1}' | awk -F "'" '{print $2}' )

echo "StringCalculation = ${StringCalculation}"

if [ ${StringCalculation} == "scf" ]; then
    echo "scf calculation"
    FlagSCF=1
else
    echo "nscf/bands calculation"
    FlagSCF=0
fi

###########################################################

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
echo "number of kpoints = $numofkpts, number of bands = $numofbnds"
#if numofbnds is undividable by 10

Error=$(echo "${NumofEQPBands} > ${numofbnds}" | bc -l)
if [ ${Error} == "1" ]; then
    echo "[ERROR] Number of eqp bands > number of total bands"
    exit 1
fi

Error=$(echo "${BandEnd} <= ${VBMindex}" | bc -l)
if [ ${Error} == "1" ]; then
    echo "[ERROR] BandEnd <= VBMindex"
    exit 1
fi


#!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!
#In QE.out, there are 8 bands in a line
#In bands.dat, there are 10 bands in a line
bandsperline=8

###################
# determine it is scf calculation or bands/nscf calculation
numoflines=$(echo $numofbnds $bandsperline | awk '{print int(($1+$2-1)/$2)}')

echo "numoflines = $numoflines"
###############################################################

#####################Loop over kpoints#########################
#Take special notice of HiSymCounter=2, which is the first one
kptstartline_eqp=$(grep -a --text -n 'End of ' $QEOUTPUT | awk -F ":" '{print $1+2}')
kptstartline_cart=$(grep -a --text -n 'number of k points=' $QEOUTPUT | awk -F ":" '{print $1}'| awk '{print $1+2}')
kptstartline_cry=$(echo "${kptstartline_cart} + ${numofkpts}+2" | bc)

echo "kptstartline_cart = ${kptstartline_cart}"
echo "kptstartline_cry = ${kptstartline_cry}"

#!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!

echo "===> Prepare temporary eigenvalue file ..."

#for ((i=1;i<=3;i++))
for ((ik=1;ik<=$numofkpts;ik++))
do
    # kptline=$(echo $i $kptstartline | awk '{print $2+($1-1)}')
    # echo "kptstartline_eqp = ${kptstartline_eqp}"

    # echo "G = ($Gx, $Gy, $Gz)"
    # #High symmetry kpoint in cartesian coordinate
    # Kx=$(echo $Gx0 $Gy0 $Gz0 $b1x $b2x $b3x | awk '{printf("%3.8f\n",$1*$4+$2*$5+$3*$6)}')
    # Ky=$(echo $Gx0 $Gy0 $Gz0 $b1y $b2y $b3y | awk '{printf("%3.8f\n",$1*$4+$2*$5+$3*$6)}')
    # Kz=$(echo $Gx0 $Gy0 $Gz0 $b1z $b2z $b3z | awk '{printf("%3.8f\n",$1*$4+$2*$5+$3*$6)}')
    # echo "High symmetry kpoint in cartesian coordinate:"
    # echo "K = ($Kx, $Ky, $Kz)"

    # #transform into VASP unit
    # KLengthout=$(echo $KLength $transconstant | awk '{printf("%15.10f",$1/$2)}')
    # echo -e "$KLengthout " >> $KPTFILE

    #!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!
    # nscf/bands calculations, no occupation lines
    if [ $FlagSCF == "0" ]; then
        eigstartline=$(echo $numoflines ${ik} ${kptstartline_eqp} | awk '{print $3+2+($1+3)*($2-1)}')
        # echo "eigstartline = $eigstartline"
        eigendline=$(echo $eigstartline $numoflines | awk '{print $1+$2-1}')
        # echo "eigendline = $eigendline"
        # scf calculations, with occupation lines
    else
        eigstartline=$(echo $numoflines ${ik} ${kptstartline_eqp} | awk '{print $3+2+(2*$1+5)*($2-1)}')
        # echo "eigstartline = $eigstartline"
        eigendline=$(echo $eigstartline $numoflines | awk '{print $1+$2-1}')
        # echo "eigendline = $eigendline"
    fi

    #!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!
    for ((j=$eigstartline;j<$eigendline+1;j++))
    do
        echo -n -e "$(sed -n "$j p" $INFILE)" >> $TEMPEIGFILE
    done

    echo -e "" >> $TEMPEIGFILE

done

###########################
echo "===> Prepare eigenvalue file ..."

#for ((ik=1;ik<=2;ik++))
for ((ik=1;ik<=$numofkpts;ik++))
do
    #####################
    ## kptline in QE.out
    kptline=$(echo ${ik} ${kptstartline_cry} | awk '{print $2+($1-1)}')
    sed -n "${kptline} p" $INFILE | awk '{print $5,$6,$7}' | awk -F ")," '{print $1}' | awk -v numband=${NumofEQPBands} '{printf("%14.9f  %14.9f  %14.9f  %7d \n", $1, $2, $3, numband)}' >> $EIGFILE
    #####################

    #####################
    ## kptline in KP.q
    # kptline=$(echo $i | awk '{print ($1+2)}')
    # sed -n "${kptline} p" KP.q | awk -v numband=${NumofEQPBands} '{printf("%14.9f  %14.9f  %14.9f %7d \n",$1, $2, $3, numband)}' >> $EIGFILE
    # sed -n "${kptstartline} p" KP.q | awk -v numband=${NumofEQPBands} '{printf("%14.9f  %14.9f  %14.9f %7d \n",$1, $2, $3, numband)}' >> $EIGFILE
    #####################

    sed -n "${ik} p" ${TEMPEIGFILE} | awk -v bandstart=${BandStart} -v bandend=${BandEnd} '{for (i=bandstart;i<=bandend;i++) printf("%8d %8d %16.9f \n",1,i,$i) }' >> $EIGFILE

done

#######
VBMindex_with_offset=$(echo "${VBMindex}-${BandStart}+1" | bc)
# echo "VBMindex_with_offset = ${VBMindex_with_offset}"

# #####
VBmax=-10000
CBmin=10000
ikc=0
ikv=0

echo "===> Get bandedge ..."


#for ((ik=1;ik<=3;ik++))
for ((ik=1;ik<=$numofkpts;ik++))
do
    # echo "k # ${ik}"
    # echo "${VBMindex_with_offset}+(${ik}-1)*(${NumofEQPBands}+1)+1" | bc
    # echo "${VBMindex_with_offset}+(${ik}-1)*(${NumofEQPBands}+1)+2" | bc

    # sed -n "$( echo "${VBMindex_with_offset}+(${ik}-1)*(${NumofEQPBands}+1)+1" | bc) p" $EIGFILE | awk '{print $3}' | awk '{printf("%16.9f \n",$1)}'
    # sed -n "$( echo "${VBMindex_with_offset}+(${ik}-1)*(${NumofEQPBands}+1)+2" | bc) p" $EIGFILE | awk '{print $3}' | awk '{printf("%16.9f \n",$1)}'

    VB=$(sed -n "$( echo "${VBMindex_with_offset}+(${ik}-1)*(${NumofEQPBands}+1)+1" | bc) p" $EIGFILE | awk '{print $3}' | awk '{printf("%16.9f",$1)}' )

    CB=$(sed -n "$( echo "${VBMindex_with_offset}+(${ik}-1)*(${NumofEQPBands}+1)+2" | bc) p" $EIGFILE | awk '{print $3}' | awk '{printf("%16.9f",$1)}' )

    Vcompare=$(echo "${VB} > ${VBmax}" | bc -l )
    #echo "VB = ${VB} VBmax = ${VBmax} Vcompare = ${Vcompare}"
    if [ ${Vcompare} == "1" ]; then
        VBmax=${VB}
        ikv=${ik}
    fi

    Ccompare=$(echo "${CB} < ${CBmin}" | bc -l )
    #echo "CB = ${CB} CBmin = ${CBmin} Ccompare = ${Ccompare}"
    if [ ${Ccompare} == "1" ]; then
        CBmin=${CB}
        ikc=${ik}
    fi

done

echo "========================================================"

# # Calculate bandgap at Gamma point
# VB=$(sed -n "$( echo "${VBMindex}+1" | bc) p" $EIGFILE | awk '{print $3}' | awk '{printf("%16.9f",$1)}' )
# CB=$(sed -n "$( echo "${VBMindex}+2" | bc) p" $EIGFILE | awk '{print $3}' | awk '{printf("%16.9f",$1)}' )

Eg=$(echo "${CBmin}-${VBmax}" | bc | awk '{printf("%16.9f",$1)}' )

####################
# Get indirect bandgap, direct gap at ikv, and direct gap at ikc
####################

# Direct bandgap
if [ ${ikv} == ${ikc} ]; then
    echo "< Direct bandgap >"
    echo " === VB === "
    echo "ikv = ${ikv}"
    kptline=$(echo ${ikv} ${kptstartline_cry} | awk '{print $2+($1-1)}')
    kv=$(sed -n "${kptline} p" $INFILE | awk '{print $5,$6,$7}' | awk -F ")," '{print $1}' | awk '{printf("%14.9f  %14.9f  %14.9f \n", $1, $2, $3)}')
    echo "kv = ${kv}"
    echo "VBmax = ${VBmax} eV"

    echo " === CB === "
    echo "ikc = ${ikc}"
    kptline=$(echo ${ikc} ${kptstartline_cry} | awk '{print $2+($1-1)}')
    kc=$(sed -n "${kptline} p" $INFILE | awk '{print $5,$6,$7}' | awk -F ")," '{print $1}' | awk '{printf("%14.9f  %14.9f  %14.9f \n", $1, $2, $3)}')

    echo "kc = ${kc}"
    echo "CBmin = ${CBmin} eV"

    echo " ========== "
    echo "Eg = ${Eg} eV"
fi

# Indirect bandgap
if [ ${ikv} != ${ikc} ]; then
    echo "< Indirect bandgap >"
    echo " === VB === "
    echo "ikv = ${ikv}"
    kptline=$(echo ${ikv} ${kptstartline_cry} | awk '{print $2+($1-1)}')
    kv=$(sed -n "${kptline} p" $INFILE | awk '{print $5,$6,$7}' | awk -F ")," '{print $1}' | awk '{printf("%14.9f  %14.9f  %14.9f \n", $1, $2, $3)}')
    echo "kv = ${kv}"
    CBikv=$(sed -n "$( echo "${VBMindex_with_offset}+(${ikv}-1)*(${NumofEQPBands}+1)+2" | bc) p" $EIGFILE | awk '{print $3}' | awk '{printf("%16.9f",$1)}' )

    echo "VBmax = ${VBmax} eV"
    echo "CBikv = ${CBikv} eV"

    echo " === CB === "
    echo "ikc = ${ikc}"
    kptline=$(echo ${ikc} ${kptstartline_cry} | awk '{print $2+($1-1)}')
    kc=$(sed -n "${kptline} p" $INFILE | awk '{print $5,$6,$7}' | awk -F ")," '{print $1}' | awk '{printf("%14.9f  %14.9f  %14.9f \n", $1, $2, $3)}')

    echo "kc = ${kc}"

    VBikc=$(sed -n "$( echo "${VBMindex_with_offset}+(${ikc}-1)*(${NumofEQPBands}+1)+1" | bc) p" $EIGFILE | awk '{print $3}' | awk '{printf("%16.9f",$1)}' )

    echo "CBmin = ${CBmin} eV"
    echo "VBikc = ${VBikc} eV"

    Egikv=$(echo ${CBikv} ${VBmax} | awk '{print $1-$2}')
    Egikc=$(echo ${CBmin} ${VBikc} | awk '{print $1-$2}')

    echo " ========== "
    echo "Indirect Eg = ${Eg} eV"
    echo "Eg@ikv = ${Egikv} eV"
    echo "Eg@ikc = ${Egikc} eV"
fi

################################################################
echo "=======================Finished!========================"
