# This script will rearrange the bandstructure file from Wannier90
# Author : Meng Wu
# Date : 2015.12.29
# Affiliation : Physics Department, University of California, Berkeley
#
Prefix=$(ls *.win | awk -F "." '{print $1}')
echo "Prefix = $Prefix"
BandFile="${Prefix}_band.dat"
echo "BandFile = $BandFile"
KptFile="Kptlist.dat"
FlagKpoint=0
NumofKpoints=$(echo " $(sed -e '/^\s*$/q' $BandFile | wc -l) - 1" | bc)
echo "NumofKpoints = $NumofKpoints"
NumofBands=$(echo "$(wc -l < $BandFile) $NumofKpoints" | awk '{print int($1/($2+1))}')
echo "NumofBands = $NumofBands"
touch eigenvalue.temp
#
for ((i=0;i<$NumofBands;i++))
#for ((i=0;i<2;i++))
do
    startline=$(echo "${i}*(${NumofKpoints}+1)+1" | bc)
    echo "startline = $startline"
    endline=$(echo "(${i}+1)*(${NumofKpoints}+1)-1" | bc)
    echo "endline = $endline"
    if [ $FlagKpoint == 0 ]; then
        sed -n "${startline},${endline} p" $BandFile | awk '{print $1}' > $KptFile
        FlagKpoint=1
    fi
    sed -n "${startline},${endline} p" $BandFile | awk '{print $2}' > eigenvalue.temp2
    if [ $i == 0 ]; then
        cat eigenvalue.temp2 > eigenvalue.temp
    else
        paste eigenvalue.temp eigenvalue.temp2 > eigenvalue.temp3
        cat eigenvalue.temp3 > eigenvalue.temp
    fi
done

paste $KptFile eigenvalue.temp > eigenvalue

#Prepare helper file (helper3.dat)
rm -rf helper3.dat helper4.dat
touch helper3.dat
touch helper4.dat

#VBMindex
echo "VBMindex = "
read VBMindex

#PlotRangeRight
PlotRangeRight=$(tail -n 1 $KptFile | awk '{print $1}')
sed -n '7p' wannier_band.gnu | awk -F "\"  " '{for(i=2; i<=NF; i++){printf("%7.5f\n",$i)}}' > helper3.dat

echo ${VBMindex} >> helper4.dat
echo ${NumofKpoints} >> helper4.dat
echo ${NumofBands} >> helper4.dat
echo ${PlotRangeRight} >> helper4.dat
