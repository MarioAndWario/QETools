#!/bin/bash
version='Beta'
echo "========================================================"
echo "====================qrelaxed.sh V.$version======================"
echo "========================================================"
QEINPUT="QE.in"
calculation=$(grep "calculation=" ${QEINPUT} | awk -F"[']" '{print $2}' | awk -F"[']" '{print $1}' | awk '{print $1}')
echo "calculation : $calculation"
if [ $calculation == "vc-relax" ]
then
echo "We have done a 'vc-relax' calculation!"
qrelaxed_v.sh
elif [ $calculation == "relax" ]
then
echo "We have done a 'relax' calculation!"
qrelaxed_r.sh
else
echo "error!"
fi