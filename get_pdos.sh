#!/bin/bash

# PDOS of dz2 up   ==> $4
# PDOS of dz2 down ==> $5

rm -rf PDOS.dat

sed -n '2,$p' Ta1 | awk '{print $1}' > energy

sed -n '2,$p' Ta1 | awk '{print $4}' > PDOS.dat

for ((i=2;i<=13;i++))
do
    sed -n '2,$p' Ta${i} | awk '{print $4}' > PDOS_temp1
    paste PDOS_temp1 PDOS.dat | awk '{printf("%.4e \n",$1+$2)}' > PDOS_temp.dat
    mv PDOS_temp.dat PDOS.dat
done

paste energy PDOS.dat > "dz2_up.dat"

sed -n '2,$p' Ta1 | awk '{print $5}' > PDOS.dat

for ((i=2;i<=13;i++))
do
    sed -n '2,$p' Ta${i} | awk '{print $5}' > PDOS_temp1
    paste PDOS_temp1 PDOS.dat | awk '{printf("%.4e \n",$1+$2)}' > PDOS_temp.dat
    mv PDOS_temp.dat PDOS.dat
done

paste energy PDOS.dat > "dz2_down.dat"
