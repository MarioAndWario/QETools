########################################
# qrelaxed_r.sh
# Meng Wu, 20151030
# V1.0
########################################
# calculation = 'relax'
# only atomic coordinates are relaxed
########################################

#!/bin/bash
SYSTEMTIME=$(date | awk '{print $4}')
QEINPUT="QE.in"
QEOUTPUT="QE.out"
QEINPUT2="QE.in.$SYSTEMTIME"
tempfile="temp"
CELLfinal="CELL.final.q"
CELLtemp="CELL.temp.q"
POSfinal="POS.final.q"
POStemp="POS.temp.q"
#################################################################
echo    "================================="
echo    "============System info=========="
numofatoms=$(grep -a --text "number of atoms/cell" $QEOUTPUT | head -n 1 | awk '{print $5}')
echo "Number of atoms : $numofatoms"
numofelements=$(grep -a --text "number of atomic types" $QEOUTPUT | head -n 1 | awk '{print $6}')
echo "Number of elements : $numofelements"
echo    "================================="
#################################################################
SuccessFlag=$(grep -a --text -n "End final coordinates" $QEOUTPUT)
IfSuccesss=100
if [ -z "$SuccessFlag" ]; then
    IfSuccess=0
    echo "======Relaxation Job FAILED======"
    echo "================================="
    echo "====From the last ionic step====="
else
    IfSuccess=1
    echo "=====Relaxation Job SUCCEED======"
    echo "================================="
fi

# #################################################################
# ratline1=$(grep -a --text -n "CELL_PARAMETERS" $QEOUTPUT | tail -1 | awk -F":" '{print $1+1}')
# ratline2=$(echo $ratline1 | awk '{print $1+1}')
# ratline3=$(echo $ratline1 | awk '{print $1+2}')

# rat1s=$(sed -n "$ratline1 p" $QEOUTPUT | awk '{print $1,$2,$3}')
# rat2s=$(sed -n "$ratline2 p" $QEOUTPUT | awk '{print $1,$2,$3}')
# rat3s=$(sed -n "$ratline3 p" $QEOUTPUT | awk '{print $1,$2,$3}')

# ra1x=$(echo $rat1s | awk '{print $1}')
# ra1y=$(echo $rat1s | awk '{print $2}')
# ra1z=$(echo $rat1s | awk '{print $3}')

# ra2x=$(echo $rat2s | awk '{print $1}')
# ra2y=$(echo $rat2s | awk '{print $2}')
# ra2z=$(echo $rat2s | awk '{print $3}')

# ra3x=$(echo $rat3s | awk '{print $1}')
# ra3y=$(echo $rat3s | awk '{print $2}')
# ra3z=$(echo $rat3s | awk '{print $3}')

# echo "CELL_PARAMETERS angstrom"
# echo -e "$ra1x \t $ra1y \t $ra1z"
# echo -e "$ra2x \t $ra2y \t $ra2z"
# echo -e "$ra3x \t $ra3y \t $ra3z"
# if [ "$IfSuccess" == "1"  ]; then
#    rm -rf $CELLfinal
#    echo "CELL_PARAMETERS angstrom"   >> $CELLfinal
#    echo -e "$ra1x \t $ra1y \t $ra1z" >> $CELLfinal
#    echo -e "$ra2x \t $ra2y \t $ra2z" >> $CELLfinal
#    echo -e "$ra3x \t $ra3y \t $ra3z" >> $CELLfinal
# elif [ "$IfSuccess" == "0" ]; then
#    rm -rf $CELLtemp
#    echo "CELL_PARAMETERS angstrom"   >> $CELLtemp
#    echo -e "$ra1x \t $ra1y \t $ra1z" >> $CELLtemp
#    echo -e "$ra2x \t $ra2y \t $ra2z" >> $CELLtemp
#    echo -e "$ra3x \t $ra3y \t $ra3z" >> $CELLtemp
# fi
# echo "================================="
############################################################

posiline=$(grep -a --text -n "ATOMIC_POSITIONS" $QEOUTPUT | tail -1 | awk -F":" '{print $1+1}')

echo "ATOMIC_POSITIONS crystal"
for ((i=0;i<$numofatoms;i++))
do
    sed -n "$(echo "$posiline+$i" | bc ) p" $QEOUTPUT | awk '{printf("%s  %2.9f  %2.9f   %2.9f  %d  %d  %d \n",$1,$2,$3,$4,1,1,1)}'
done
###########################################################
if [ "$IfSuccess" == "1" ];then
    rm -rf $POSfinal
    echo "ATOMIC_POSITIONS crystal" >> $POSfinal
    for ((i=0;i<$numofatoms;i++))
    do
        sed -n "$(echo "$posiline+$i" | bc ) p" $QEOUTPUT | awk '{printf("%s  %2.9f  %2.9f %2.9f  %d  %d  %d \n",$1,$2,$3,$4,1,1,1)}' >> $POSfinal
    done
elif [ "$IfSuccess" == "0" ]; then
    rm -rf $POStemp
    echo "ATOMIC_POSITIONS crystal" >> $POStemp
    for ((i=0;i<$numofatoms;i++))
    do
        sed -n "$(echo "$posiline+$i" | bc ) p" $QEOUTPUT | awk '{printf("%s  %2.9f  %2.9f %2.9f  %d  %d  %d \n",$1,$2,$3,$4,1,1,1)}' >> $POStemp
    done
fi

