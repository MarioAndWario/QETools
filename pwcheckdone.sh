#!/bin/bash
KPOINTSPREFIX="KP"
PTLIB="kptlib"
PTLOG="kgrid.log"
OUTPUT="QE.out"
#################################################################
#Default: 1 to end

if [ $# -gt 3 ]; then
   echo "USAGE: wfnbatch.sh [SUBFLAG:1=true,i=interactive,f=force,d=delete,else=false] [StartIndex] [EndIndex] "
   exit 0
fi
echo "Number of kpoints file: $(sed -n '2 p' ${PTLIB}/${PTLOG} | awk '{print $5}') "
SUBFLAG=1
StartIndex=1
EndIndex=$(sed -n '2 p' ${PTLIB}/${PTLOG} | awk '{print $5}')

for ((i=$StartIndex;i<=$EndIndex;i++))
do
  if [ ! -d P_${i} ];then
     echo "!!!!! P_${i} does not exist! !!!!!"
  else
     cd P_${i}
     string="$(grep "JOB DONE" $OUTPUT)"
     if [ -z "$string" ];then
        echo "***** Job #$i not finished! *****" 
     else
        echo "===== Job #$i has finished! ====="
     fi
     cd ..
  fi
done
