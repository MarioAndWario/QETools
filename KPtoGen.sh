#!/bin/bash

# This script will transfrom KP.q into suitable format for general interpolation functionality of Wannier90

InputFile="KP.q"
OutputFile="geninterp.kpt"
NumofKpts=$(wc -l KP.q | awk '{print $1-2}')

rm -rf ${OutputFile}

echo "NumofKpts = ${NumofKpts}"

echo "general band interpolation" > ${OutputFile}
echo "crystal" >> ${OutputFile}
echo "${NumofKpts}" >> ${OutputFile}

sed -n '3,$ p' ${InputFile} | awk '{print NR,"  ",$1,"  ",$2,"  ",$3}' >> ${OutputFile}

echo "======= Finished ======"
