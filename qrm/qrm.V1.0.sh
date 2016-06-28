#!/bin/bash
QEinput="QE.in"
prefix=$(grep "prefix" ${QEinput} | awk -F"[']" '{print $2}')
echo "We are deleting files for prefix = ${prefix} ..."
rm -rf ${prefix}.r* ${prefix}.w* ${prefix}.m* ${prefix}.i* CRASH
