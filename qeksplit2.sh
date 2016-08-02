#!/bin/bash
#This script split the kpts file into bins with required size

if [ -f "kpoints_all.dat" ]; then
    echo "We are using subsampling q0 points"
    INPUT="kpoints_all.dat"
    SUBFLAG=1
else
    if [ -f "out.kgrid" ]; then
        echo "We are using regular single q0 point"
        INPUT="out.kgrid"
        SUBFLAG=0
    else
        echo "No input kpoints file found, sorry ..."
        exit 0
    fi
fi

LOGFILE="kgrid.log"
OUTPUTPREFIX="KP"

#Clean
rm -f ${OUTPUTPREFIX}*
rm -f $LOGFILE

numoftotalkpts=$( wc -l $INPUT | awk '{print $1-2}')
echo "Total number of kpts = $numoftotalkpts"

if [ ! -z $1  ]; then
    numofkpt1=$1
else
    echo "Please input the required number of kpts per file: "
    read numofkpt1
fi
numoffiles0=$( echo $numoftotalkpts $numofkpt1 | awk '{print int($1/$2)}' )
#echo $numoffiles
numofkpt2=$( echo $numoftotalkpts $numoffiles0 $numofkpt1 | awk '{print $1-$2*$3}' )

if [ $numofkpt2 == 0 ]
then
    DevFlag=1
    echo "The number of total kpts ( $numoftotalkpts ) are dividable by the number of files ($numoffiles0) : $numoftotalkpts = $numoffiles0 * $numofkpt1  "
    echo "The number of total kpts ( $numoftotalkpts ) are dividable by the number of files ($numoffiles0) : $numoftotalkpts = $numoffiles0 * $numofkpt1  " > $LOGFILE
    numoffiles=$numoffiles0
else
    DevFlag=0
    echo "The number of total kpts ( $numoftotalkpts ) are NOT dividable by the number of files ($numoffiles0) : $numoftotalkpts = $numoffiles0 * $numofkpt1 + $numofkpt2"
    echo "The number of total kpts ( $numoftotalkpts ) are NOT dividable by the number of files ($numoffiles0) : $numoftotalkpts = $numoffiles0 * $numofkpt1 + $numofkpt2" > $LOGFILE
    numoffiles=$(echo "$numoffiles0+1" | bc)
fi

echo "Number of files : $numoffiles "
for ((i=1;i<$numoffiles;i++))
do
    startline=$(echo $i $numofkpt1 | awk '{print ($1-1)*$2+3}')
    endline=$(echo $i $numofkpt1 | awk '{print $1*$2+2}')
  #echo $startline $endline
    echo "KPOINTS crystal" > ${OUTPUTPREFIX}$i
    echo $numofkpt1 >> ${OUTPUTPREFIX}$i
    sed -n "$startline, $endline p" $INPUT >> ${OUTPUTPREFIX}$i
done

if [ $numoffiles -gt 1 ];then
##Special treatment of the last file
    startline=$(echo $numoffiles $numofkpt1 | awk '{print ($1-1)*$2+3}')
    if [ $DevFlag -eq 1 ]; then
        echo "KPOINTS crystal" > ${OUTPUTPREFIX}$i
        echo $numofkpt1 >> ${OUTPUTPREFIX}$i
    else
        echo "KPOINTS crystal" > ${OUTPUTPREFIX}$i
        echo $numofkpt2 >> ${OUTPUTPREFIX}$i
    fi
    sed -n "$startline, \$ p" $INPUT >> ${OUTPUTPREFIX}${numoffiles}
else
    if [ $numoffiles -eq 1 ]; then
#Only one file
        startline=$(echo $numoffiles $numofkpt1 | awk '{print ($1-1)*$2+3}')
        echo "KPOINTS crystal" > ${OUTPUTPREFIX}1
        echo $numoftotalkpts >> ${OUTPUTPREFIX}1
   #echo $numofkpt1
        sed -n "$startline, \$ p" $INPUT >> ${OUTPUTPREFIX}1
    fi
fi
#Write log
echo "Number of files = $numoffiles" >> $LOGFILE
