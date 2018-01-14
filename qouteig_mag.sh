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
KPTFILE="Klength.dat"
EIGFILE="Eig.dat"
EIGSHIFTFILE="Eig.shift.dat"
TEMPEIGFILE="tempEig.dat"
BANDSFILE="eigenvalue"
BANDSSHIFTFILE="eigenvalue.shift"
FERMIENERGYFILE="../nscf/QE.out"
Helper1="helper1.dat"
Helper2="helper2.dat"
echo "========================================================"
echo "====================qouteig.sh V.$version===================="
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
FlagNSpin=$(grep -a --text 'nspin' $QEINPUT | awk -F "=" '{print $2}' | awk -F "," '{print $1}' | awk '{print $1}')
#echo ${FlagNSpin}
if [ $FlagNSpin -eq 1 ]; then
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

echo "kptstartline2 = $kptstartline2"

if [ -z $kptstartline2 ]; then
   echo ">>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>"
   echo "You are not doing a band structure calculations, check your IN.q!"
   exit 123
fi

echo "kptstartline = $kptstartline"
#!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!
for ((i=1;i<=$numofkpts;i++))
do
    kptline=$(echo $i $kptstartline | awk '{print $2+($1-1)}')

    if [ $FlagChangeStartingPoint -eq 1 ]; then
#!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!
        if [ $HiSymCounter -eq 2 ]; then
            kpttargetline=$(echo $i $kptstartline | awk '{print $2+$1}')
        else
            kpttargetline=$kptline
        fi

        echo "kpttargetline = $kpttargetline" 
#!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!
#Read in the high symmetry points in crystal fractional coordinate
        Gx0=$(grep -a --text -A $HiSymCounter "K_POINTS" $QEINPUT | tail -1 | awk '{print $1}')
        Gy0=$(grep -a --text -A $HiSymCounter "K_POINTS" $QEINPUT | tail -1 | awk '{print $2}')
        Gz0=$(grep -a --text -A $HiSymCounter "K_POINTS" $QEINPUT | tail -1 | awk '{print $3}')
        echo "========================================================"
        echo "High symmetry points in crystal fractional coordinate:"
        echo "G0 = ($Gx0, $Gy0, $Gz0)"
        segmentlength=$(grep -a --text -A $HiSymCounter "K_POINTS" $QEINPUT | tail -1 | awk '{print $4}')
        echo $segmentlength >> $Helper1
###########counter for the number of segments
        segmentcounter=0
###########Switch off the flag for changing the starting point
        FlagChangeStartingPoint=0
###########Update High symmetry pointer counter
        HiSymCounter=$(echo $HiSymCounter | awk '{print $1+1}')

#echo "kptline = $kptline"
#echo "$(sed -n "$kptline p" $INFILE)" >> $KPTFILE
#Read in the next point in cartesian coordinate
#!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!
        Gx=$(sed -n "$kpttargetline p" $QEOUTPUT | awk -F "=" '{print $2}' | awk -F "(" '{print $2}' | awk -F ")" '{print $1}' | awk '{print $1}')
        Gy=$(sed -n "$kpttargetline p" $QEOUTPUT | awk -F "=" '{print $2}' | awk -F "(" '{print $2}' | awk -F ")" '{print $1}' | awk '{print $2}')
        Gz=$(sed -n "$kpttargetline p" $QEOUTPUT | awk -F "=" '{print $2}' | awk -F "(" '{print $2}' | awk -F ")" '{print $1}' | awk '{print $3}')
#Gx=$(sed -n "$kpttargetline p" $QEOUTPUT | awk '{print $3}')
#Gy=$(sed -n "$kpttargetline p" $QEOUTPUT | awk '{print $4}')
#Gz=$(sed -n "$kpttargetline p" $QEOUTPUT | awk '{print $5}')
#!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!
        echo "G = ($Gx, $Gy, $Gz)"

#High symmetry kpoint in cartesian coordinate
        Kx=$(echo $Gx0 $Gy0 $Gz0 $b1x $b2x $b3x | awk '{printf("%3.8f\n",$1*$4+$2*$5+$3*$6)}')
        Ky=$(echo $Gx0 $Gy0 $Gz0 $b1y $b2y $b3y | awk '{printf("%3.8f\n",$1*$4+$2*$5+$3*$6)}')
        Kz=$(echo $Gx0 $Gy0 $Gz0 $b1z $b2z $b3z | awk '{printf("%3.8f\n",$1*$4+$2*$5+$3*$6)}')
        echo "High symmetry kpoint in cartesian coordinate:"
        echo "K = ($Kx, $Ky, $Kz)"

        echo "segmentlength = $segmentlength"
#Delta G in cartesian coordinates
        DGx=$(echo $Gx $Kx | awk '{print $1-$2}')
        DGy=$(echo $Gy $Ky | awk '{print $1-$2}')
        DGz=$(echo $Gz $Kz | awk '{print $1-$2}')

echo "DG = ($DGx, $DGy, $DGz)"

        DLength=$(echo $DGx $DGy $DGz | awk '{printf("%3.8f\n",sqrt($1*$1+$2*$2+$3*$3))}')
    fi

    if [ $i -eq 1 -o $segmentlength -eq 1 ];then
        KLength=$(echo $KLength| awk '{print $1}' )
    else
        KLength=$(echo $KLength $DLength | awk '{print $1+$2}' )
    fi
echo "KLength = $KLength"
#transform into VASP unit
    KLengthout=$(echo $KLength $transconstant | awk '{printf("%15.10f",$1/$2)}')
    echo -e "$KLengthout " >> $KPTFILE

#!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!
    eigstartline=$(echo $numoflines $i $kptstartline2 | awk '{print $3+2+($1+3)*($2-1)}')
echo $eigstartline
    eigendline=$(echo $eigstartline $numoflines | awk '{print $1+$2}')
echo $eigendline
#!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!

    for ((j=$eigstartline;j<$eigendline+1;j++))
    do
        echo -n -e "$(sed -n "$j p" $INFILE)" >> $TEMPEIGFILE
    done
    echo -e "" >> $TEMPEIGFILE

################################################################
####################Sorting the eigenvalues#####################
    tail -1 $TEMPEIGFILE | awk ' {split( $0, a, " " ); asort( a ); for( i = 1; i <= length(a); i++ ) printf( "%s ", a[i] ); printf( "\n" ); }'>> $EIGFILE

################################################################
#Judge if we need to turn on the $FlagChangeStartingPoint
    segmentcounter=$(echo $segmentcounter | awk '{print $1+1}')
    if [ $HiSymCounter -eq 3 ];then
        if [ $segmentcounter -gt $segmentlength ]; then
            FlagChangeStartingPoint=1
        fi
    else
        if [ $segmentcounter -eq $segmentlength ]; then
            FlagChangeStartingPoint=1
        fi
    fi
done

##################
## Spin DOWN states
echo " <<<< Spin DOWN bands >>>>"
###############################################################
#####################Loop over kpoints#########################
#Take special notice of HiSymCounter=2, which is the first one
kptstartline2=$(grep -a --text -n 'SPIN DOWN' $QEOUTPUT | awk -F ":" '{print $1+3}')

kptstartline=$(grep -a --text -n 'number of k points=' $QEOUTPUT | awk -F ":" '{print $1}'| awk '{print $1+2}')

echo "kptstartline2 = $kptstartline2"

if [ -z $kptstartline2 ]; then
   echo ">>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>"
   echo "You are not doing a band structure calculations, check your IN.q!"
   exit 123
fi

echo "kptstartline = $kptstartline"
#!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!
for ((i=1;i<=$numofkpts;i++))
do
    kptline=$(echo $i $kptstartline | awk '{print $2+($1-1)}')

    if [ $FlagChangeStartingPoint -eq 1 ]; then
#!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!
        if [ $HiSymCounter -eq 2 ]; then
            kpttargetline=$(echo $i $kptstartline | awk '{print $2+$1}')
        else
            kpttargetline=$kptline
        fi

        echo "kpttargetline = $kpttargetline" 
#!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!
#Read in the high symmetry points in crystal fractional coordinate
        Gx0=$(grep -a --text -A $HiSymCounter "K_POINTS" $QEINPUT | tail -1 | awk '{print $1}')
        Gy0=$(grep -a --text -A $HiSymCounter "K_POINTS" $QEINPUT | tail -1 | awk '{print $2}')
        Gz0=$(grep -a --text -A $HiSymCounter "K_POINTS" $QEINPUT | tail -1 | awk '{print $3}')
        echo "========================================================"
        echo "High symmetry points in crystal fractional coordinate:"
        echo "G0 = ($Gx0, $Gy0, $Gz0)"
        segmentlength=$(grep -a --text -A $HiSymCounter "K_POINTS" $QEINPUT | tail -1 | awk '{print $4}')
        echo $segmentlength >> $Helper1
###########counter for the number of segments
        segmentcounter=0
###########Switch off the flag for changing the starting point
        FlagChangeStartingPoint=0
###########Update High symmetry pointer counter
        HiSymCounter=$(echo $HiSymCounter | awk '{print $1+1}')

#echo "kptline = $kptline"
#echo "$(sed -n "$kptline p" $INFILE)" >> $KPTFILE
#Read in the next point in cartesian coordinate
#!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!
        Gx=$(sed -n "$kpttargetline p" $QEOUTPUT | awk -F "=" '{print $2}' | awk -F "(" '{print $2}' | awk -F ")" '{print $1}' | awk '{print $1}')
        Gy=$(sed -n "$kpttargetline p" $QEOUTPUT | awk -F "=" '{print $2}' | awk -F "(" '{print $2}' | awk -F ")" '{print $1}' | awk '{print $2}')
        Gz=$(sed -n "$kpttargetline p" $QEOUTPUT | awk -F "=" '{print $2}' | awk -F "(" '{print $2}' | awk -F ")" '{print $1}' | awk '{print $3}')
#Gx=$(sed -n "$kpttargetline p" $QEOUTPUT | awk '{print $3}')
#Gy=$(sed -n "$kpttargetline p" $QEOUTPUT | awk '{print $4}')
#Gz=$(sed -n "$kpttargetline p" $QEOUTPUT | awk '{print $5}')
#!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!
        echo "G = ($Gx, $Gy, $Gz)"

#High symmetry kpoint in cartesian coordinate
        Kx=$(echo $Gx0 $Gy0 $Gz0 $b1x $b2x $b3x | awk '{printf("%3.8f\n",$1*$4+$2*$5+$3*$6)}')
        Ky=$(echo $Gx0 $Gy0 $Gz0 $b1y $b2y $b3y | awk '{printf("%3.8f\n",$1*$4+$2*$5+$3*$6)}')
        Kz=$(echo $Gx0 $Gy0 $Gz0 $b1z $b2z $b3z | awk '{printf("%3.8f\n",$1*$4+$2*$5+$3*$6)}')
        echo "High symmetry kpoint in cartesian coordinate:"
        echo "K = ($Kx, $Ky, $Kz)"

        echo "segmentlength = $segmentlength"
#Delta G in cartesian coordinates
        DGx=$(echo $Gx $Kx | awk '{print $1-$2}')
        DGy=$(echo $Gy $Ky | awk '{print $1-$2}')
        DGz=$(echo $Gz $Kz | awk '{print $1-$2}')

echo "DG = ($DGx, $DGy, $DGz)"

        DLength=$(echo $DGx $DGy $DGz | awk '{printf("%3.8f\n",sqrt($1*$1+$2*$2+$3*$3))}')
    fi

    if [ $i -eq 1 -o $segmentlength -eq 1 ];then
        KLength=$(echo $KLength| awk '{print $1}' )
    else
        KLength=$(echo $KLength $DLength | awk '{print $1+$2}' )
    fi
echo "KLength = $KLength"
#transform into VASP unit
    KLengthout=$(echo $KLength $transconstant | awk '{printf("%15.10f",$1/$2)}')
    echo -e "$KLengthout " >> $KPTFILE

#!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!
    eigstartline=$(echo $numoflines $i $kptstartline2 | awk '{print $3+2+($1+3)*($2-1)}')
echo $eigstartline
    eigendline=$(echo $eigstartline $numoflines | awk '{print $1+$2}')
echo $eigendline
#!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!

    for ((j=$eigstartline;j<$eigendline+1;j++))
    do
        echo -n -e "$(sed -n "$j p" $INFILE)" >> $TEMPEIGFILE
    done
    echo -e "" >> $TEMPEIGFILE

################################################################
####################Sorting the eigenvalues#####################
    tail -1 $TEMPEIGFILE | awk ' {split( $0, a, " " ); asort( a ); for( i = 1; i <= length(a); i++ ) printf( "%s ", a[i] ); printf( "\n" ); }'>> $EIGFILE

################################################################
#Judge if we need to turn on the $FlagChangeStartingPoint
    segmentcounter=$(echo $segmentcounter | awk '{print $1+1}')
    if [ $HiSymCounter -eq 3 ];then
        if [ $segmentcounter -gt $segmentlength ]; then
            FlagChangeStartingPoint=1
        fi
    else
        if [ $segmentcounter -eq $segmentlength ]; then
            FlagChangeStartingPoint=1
        fi
    fi
done

################################################################
############## Paste the klength and eigs together #############
echo $VBMindex $numofkpts $numofbnds $(tail -1 $KPTFILE) > $Helper2
paste -d" " $KPTFILE $EIGFILE > $BANDSFILE

echo "numofbnds = $numofbnds"
############ Set Fermi energy as the reference energy ##########
awk '{
        for (i=1;i<='${numofbnds}';i++){
            printf("%3.6f ",$i-('${EFermi}'))
        }
        printf("\n")
        }' $EIGFILE > $EIGSHIFTFILE
paste -d" " $KPTFILE $EIGSHIFTFILE > $BANDSSHIFTFILE

rm -rf $KPTFILE
rm -rf $EIGSHIFTFILE
rm -rf $EIGFILE
rm -rf $TEMPEIGFILE

################################################################
echo "=======================Finished!========================"
