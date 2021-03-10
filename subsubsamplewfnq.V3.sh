#!/bin/bash
#SBATCH --partition=debug
#SBATCH --nodes=10
#SBATCH --time=00:30:00
#SBATCH --job-name=my_job
#SBATCH --license=SCRATCH
#SBATCH -C haswell

# This script will submit several jobs to generate chi0mat.h5 for each subsampling qpoint
# We need to setup template and cc_q0s.inp to proceed
RUN="srun -n 320"
iq_start=1
iq_end=3
NKPOOL=10
DirTemplate="template"
#Qfile="cc_q0s.inp"
#DirWFNmq="/scratch1/03355/tg826544/InSe/semicore/6x6x1/WFNmq/"
#FILE_WFNmq="WFNmq.h5"
DirCurrent=$(pwd)
for ((iq=${iq_start};iq<=${iq_end};iq++))
do
    KPFILE=kpoints_wfnmq_${iq}.dat
    d1kvector=$(sed -n "3 p" ./klib/${KPFILE} | awk '{print $1}')
    d2kvector=$(sed -n "3 p" ./klib/${KPFILE} | awk '{print $2}')
    d3kvector=$(sed -n "3 p" ./klib/${KPFILE} | awk '{print $3}')
    echo "iq = ${iq} : ${d1kvector} ${d2kvector} ${d3kvector}"
    DirName="Q${iq}"
    if [ -d ${DirName} ]; then
        echo "${DirName} exist."
    else
        cp -r ${DirTemplate} ${DirName}
    fi
    cd $DirName

    # QE calculation
    INPUT="QE.in"
    OUTPUT="QE.out"
    EXENAME="pw.x -nk ${NKPOOL}"
    cp ../klib/${KPFILE} ./KP.q

    if [ -f "${OUTPUT}" ]; then
        if [ -z "$(grep "JOB DONE." ${OUTPUT})" ]; then
            echo "${OUTPUT} did not finish, restart ${EXENAME} calculation"
            DO_RUN_QE="T"
        else
            echo "Finished. Skip this ${EXENAME} calculation..."
            DO_RUN_QE="F"
        fi
    else
        DO_RUN_QE="T"
    fi

    if [ ${DO_RUN_QE} == "T" ]; then
        echo "Start ${EXENAME} calculation"
        qassemble.sh
        # sleep 2
        # ${RUN} ${EXENAME} < ${INPUT} > ${OUTPUT} 2>&1
        # if [ ! -z "$(grep "TOTAL:" ${OUTPUT})" ]; then
        #     echo "Finish ${EXENAME} calculation"
        # fi
    fi

    # PW2BGW calculation
    INPUT="pw2bgw.inp"
    sed -i "/^  wfng_dk1 =/c\  wfng_dk1 = ${d1kvector}" pw2bgw.inp
    sed -i "/^  wfng_dk2 =/c\  wfng_dk2 = ${d2kvector}" pw2bgw.inp
    sed -i "/^  wfng_dk3 =/c\  wfng_dk3 = ${d3kvector}" pw2bgw.inp

    OUTPUT="pw2bgw.out"
    EXENAME="pw2bgw.x -nk 1"

    if [ ${DO_RUN_QE} == "F" ]; then
        if [ -f "${OUTPUT}" ]; then
            if [ -z "$(grep "JOB DONE." ${OUTPUT})" ]; then
                echo "${OUTPUT} did not finish, restart ${EXENAME} calculation"
                DO_RUN="T"
            else
                echo "Finished. Skip this ${EXENAME} calculation..."
                DO_RUN="F"
            fi
        else
            DO_RUN="T"
        fi
    else
        echo "QE is fresh, do pw2bgw anyway."
        DO_RUN="T"
    fi

    if [ ${DO_RUN} == "T" ]; then
        echo "Start ${EXENAME} calculation"
        # ${RUN} ${EXENAME} < ${INPUT} > ${OUTPUT} 2>&1
        # if [ ! -z "$(grep "TOTAL:" ${OUTPUT})" ]; then
        #     echo "Finish ${EXENAME} calculation"
        # fi
    fi

    # # WFN2HDF calculation
    # OUTPUT="wfn2hdf.out"
    # EXENAME="wfn2hdf.x BIN WFN WFN.h5"

    # if [ -f "${OUTPUT}" ]; then
    #     if [ -z "$(grep "JOB DONE." ${OUTPUT})" ]; then
    #         echo "${OUTPUT} did not finish, restart ${EXENAME} calculation"
    #         DO_RUN="T"
    #     else
    #         echo "Finished. Skip this ${EXENAME} calculation..."
    #         DO_RUN="F"
    #     fi
    # else
    #     DO_RUN="T"
    # fi

    echo "============================="

    cd ${DirCurrent}
done
