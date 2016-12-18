#!/bin/bash
# This script will distribute kpoints list into sigma.inp and prepare the directories

ProtoDir="proto"
LIBK="libK"
JobStart=2
JobEnd=16
for ((ijob=${JobStart};ijob<=${JobEnd};ijob++))
do
    DirName="K${ijob}"
    # if [ -d ${DirName} ]; then
    #    echo "${DirName} exists! q: quit, d: delete ?"
    #    read DELflag
    #    if [ ${DELflag} == "d" ]; then
    #       echo "Remove ${DirName}"
    #       rm -rf ${DirName}
    #    else
    #       echo "Exit ..."
    #       exit 2
    #    fi
    # fi
    # cp -r ${ProtoDir} ${DirName}
    cd ${DirName}   
    #cp ../${LIBK}/KP${ijob} ./KP.q
    sbatch subpw2bgw.sh
    cd ..
done