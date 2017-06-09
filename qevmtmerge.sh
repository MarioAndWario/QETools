#!/bin/bash
# This script will distribute kpoints list into sigma.inp and prepare the directories

ProtoDir="proto"
LIBK="libK"
WFNmergeDir="vmtmerge"
JobStart=1
JobEnd=5

if [ ! -d ${WFNmergeDir} ]; then
   mkdir ${WFNmergeDir}
fi

for ((ijob=${JobStart};ijob<=${JobEnd};ijob++))
do
    DirName="K${ijob}"
    if [ ! -d ${DirName} ]; then
       echo "${DirName} does not exist!"
       exit
    else
    ln -sf ../${DirName}/vmt.x.dat ./${WFNmergeDir}/vmt.${ijob}.x.dat
    ln -sf ../${DirName}/vmt.y.dat ./${WFNmergeDir}/vmt.${ijob}.y.dat
    ln -sf ../${DirName}/vmt.z.dat ./${WFNmergeDir}/vmt.${ijob}.z.dat
    fi
done
