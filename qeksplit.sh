#!/bin/bash
#This script split the kpts file into bins
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
rm -f $LOGFILE
rm -f $OUTPUTPREFIX*

numoftotalkpts=$( wc -l $INPUT | awk '{print $1-2}')
echo "Total number of kpoints : $numoftotalkpts"
#####################################################
if [ ! -z $1  ]; then
   numoffiles=$1
else
   echo "Please input the required number of splited files : "
   read numoffiles 
fi

#####################################################
numofkpt1=$( echo $numoftotalkpts $numoffiles | awk '{print int($1/$2)}' )
#echo $numofkpt1
numofkpt2=$( echo $numoftotalkpts $numoffiles $numofkpt1 | awk '{print $1-$2*$3}' )
#echo $numofkpt2

if [ $numofkpt2 == 0 ]
then
   echo "The number of total kpts ( $numoftotalkpts ) are dividable by the number of files ($numoffiles) : $numoftotalkpts = $numoffiles * $numofkpt1  "
   echo "The number of total kpts ( $numoftotalkpts ) are dividable by the number of files ($numoffiles) : $numoftotalkpts = $numoffiles * $numofkpt1  " > $LOGFILE
else
   echo "The number of total kpts ( $numoftotalkpts ) are NOT dividable by the number of files ($numoffiles) : $numoftotalkpts = $( echo "$numoffiles-1" | bc ) * $numofkpt1 + $( echo "$numofkpt1+$numofkpt2" | bc )"
   echo "The number of total kpts ( $numoftotalkpts ) are NOT dividable by the number of files ($numoffiles) : $numoftotalkpts = $( echo "$numoffiles-1" | bc ) * $numofkpt1 + $( echo "$numofkpt1+$numofkpt2" | bc )" > $LOGFILE
fi

for ((i=1;i<numoffiles;i++))
do
   startline=$(echo $i $numofkpt1 | awk '{print ($1-1)*$2+3}')
   endline=$(echo $i $numofkpt1 | awk '{print $1*$2+2}')
  #echo $startline $endline
   echo "K_POINTS crystal" > ${OUTPUTPREFIX}${i}
   echo $numofkpt1 >> ${OUTPUTPREFIX}${i}
   sed -n "$startline, $endline p" $INPUT >> ${OUTPUTPREFIX}${i}
done
#Special treatment of the last file
   startline=$(echo $i $numofkpt1 | awk '{print ($1-1)*$2+3}')
   echo $(echo $numofkpt1 $numofkpt2 | awk '{print $1+$2}') > ${OUTPUTPREFIX}${i}
   sed -n "$startline, \$ p" $INPUT >> ${OUTPUTPREFIX}${numoffiles}
#write log
echo "Number of files = $numoffiles " >> $LOGFILE
