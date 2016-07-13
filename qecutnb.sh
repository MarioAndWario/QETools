#!/bin/bash
###############################################################
####################### Descriptions ##########################
#This script read in the "QE.out" file generated from pw.x
#and arrange the eigenvalues of first kpoint(Gamma) in the
#output file "eigenvalue". And then we will calibrate the
#kinetic energy cutoff and number of bands
###############################################################
#Author: Meng Wu, Ph.D. Candidate in Physics
#Affiliation: University of California, Berkeley
#Version: 1.0
#Date: Jul. 12, 2016
######################### Variables ###########################
version='1.0'
QEINPUT="QE.in"
QEOUTPUT="QE.out"
INFILE="QE.out"
KPTFILE="Klength.dat"
EIGFILE="Eig.dat"
TEMPEIGFILE="tempEig.dat"

echo "========================================================"
echo "====================qecutnb.sh V.$version===================="
echo "========================================================"

if [ -f $EIGFILE ]; then
    rm -f $EIGFILE
fi

if [ -f $TEMPEIGFILE ]; then
    rm -f $TEMPEIGFILE
fi


###############################################################
#!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!
#numofbnds=$(sed -n '1p' $INFILE | awk '{print $3}' | awk -F"," '{print $1}' )
numofbnds=$(grep -a --text 'number of Kohn-Sham states' $QEOUTPUT | awk -F "=" '{print $2}'| awk '{print $1}')
#numofkpts=$(sed -n '1p' $INFILE | awk '{print $5}')
numofkpts=$(grep -a --text 'number of k points=' $QEOUTPUT | awk -F "=" '{print $2}' | awk '{print $1}')
#!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!
echo "number of kpoints = $numofkpts, number of bands = $numofbnds"
#if numofbnds is undividable by 10
#!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!
#In QE.out, there are 8 bands in a line
#In bands.dat, there are 10 bands in a line
bandsperline=8
numoflines=$(echo $numofbnds $bandsperline | awk '{print int(($1+$2-1)/$2)}')
#!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!
#echo "numoflines = $numoflines"
###############################################################
#####################Loop over kpoints#########################
#Take special notice of HiSymCounter=2, which is the first one
kptstartline2=$(grep -a --text -n 'End of band structure calculation' $QEOUTPUT | awk -F ":" '{print $1+2}')
kptstartline=$(grep -a --text -n 'number of k points=' $QEOUTPUT | awk -F ":" '{print $1}'| awk '{print $1+2}')
#echo "kptstartline = $kptstartline"
#!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!
eigstartline=$(echo $kptstartline2 | awk '{print $1+2}')
#echo $eigstartline
eigendline=$(echo $eigstartline $numoflines | awk '{print $1+$2}')
#echo $eigendline
#!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!

for ((j=$eigstartline;j<$eigendline+1;j++))
do
    echo -n -e "$(sed -n "$j p" $INFILE)" >> $TEMPEIGFILE
done
echo -e "" >> $TEMPEIGFILE
################################################################
####################Sorting the eigenvalues#####################
tail -1 $TEMPEIGFILE | awk ' {split( $0, a, " " ); asort( a ); for( i = 1; i <= length(a); i++ ) printf( "%s ", a[i] ); printf( "\n" ); }'>> $EIGFILE

awk -v nbnd="${numofbnds}" '
{
  break_all = 0
  for (j=0;j<20;j++)
  {
     if (break_all == 1)
     {
        break;
     }
     Elow=(j)*5;
     Ehigh=(j+1)*5;
     for (i=1;i<=nbnd;i++)
     {
         if (($i)/13.605698066 < Ehigh )
         {
            temp = i
         }
     }
     if (temp == nbnd)
     {
        #printf("%s\n", "We have reached the upper range of bands");
        break_all = 1;
        break
     }
     printf("%s %6.3f %s %d %s %6.3f %s \n","[0,",Ehigh,"Ry] : ib <= ",temp,", Eb < ", $temp,"eV");
  }
}' Eig.dat > "ecut_nb.dat"
echo "========================================================"
