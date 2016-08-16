#!/bin/bash
# This script will distribute kpoints list into sigma.inp and prepare the directories

ProtoDir="proto"
LIBK="libK"
WFNmergeDir="wfnmerge"
JobStart=1
JobEnd=4

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
    ln -sf ../${DirName}/WFN.h5 ./${WFNmergeDir}/WFN.${ijob}.h5
    ln -sf ../${DirName}/vxc.h5 ./${WFNmergeDir}/vxc.${ijob}.h5
    fi
done