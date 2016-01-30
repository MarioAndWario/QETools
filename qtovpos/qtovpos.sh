#!/bin/bash
######################################################
#This script will convert POS.q and CELL.q into POSCAR
######################################################
#Author: Meng Wu
#Date: Aug 30, 2015
######################################################
#Version 1.0
######################################################
QPOSfile="POS.q"
QCELLfile="CELL.q"
VPOSfile="POSCAR"
unit="1.0"
SystemName="Crystal"
######################################################
#CELL parameters
rm -rf $VPOSfile
echo $SystemName > $VPOSfile
echo $unit >> $VPOSfile 
sed -n '2,4 p' $QCELLfile >> $VPOSfile
######################################################
#Elements and number of atoms
echo -n "   " >> $VPOSfile
sed -n '2,$ p' $QPOSfile | awk '{print $1}' | uniq -c | awk '{print $2}' | awk 'BEGIN{ORS="  "}1' >> $VPOSfile
echo -e " " >> $VPOSfile
echo -n "   " >> $VPOSfile
sed -n '2,$ p' $QPOSfile | awk '{print $1}' | uniq -c | awk '{print $1}' | awk 'BEGIN{ORS="  "}1' >> $VPOSfile
echo -e " " >> $VPOSfile
######################################################
#Atomic positions
echo "Selective Dynamics" >> $VPOSfile
echo "Direct" >> $VPOSfile
sed -n '2,$ p' POS.q | awk '{printf("%10.9f  %10.9f  %10.9f  T  T  T  # %s \n",$2,$3,$4,$1)}' >> $VPOSfile
######################################################
