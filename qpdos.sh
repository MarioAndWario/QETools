# for each element, combine all the the orbitals in one file
# add the PDOS from specific orbitals from specfic atoms (by indices of atoms)

File_Erange='Erange.dat'

QEINPUT="QE.in"
#prefix=$(grep "prefix" ${QEINPUT} | awk -F"[']" '{print $2}' | awk '{print $1}')
#echo 'prefix : ' $prefix
prefix="PDOS"
nat=$(grep "nat" ${QEINPUT} | awk -F "[=]" '{print $2}' | awk -F '[,]' '{print $1}')
echo 'nat = ' $nat

Flag_getErange=0
#Max_orbit=1
for ((i=1;i<=$nat;i++))
do
    # clear files
    if [ -f "./pdos.$i" ]
    then
        rm -rf "pdos.$i"*
    fi

    Counter_orbit=0
    for file in ./${prefix}.pdos_atm#${i}\(*
    do
        echo $i,"-th atom", $Counter_orbit,"-th orbital"
        echo $file
        # sed Erange
        if [ $Flag_getErange == 0 ]
        then
            sed -n '2,$ p' $file | awk '{print $1}' > $File_Erange
            Flag_getErange=1
        fi
        # temporal files: pdos.i.orbit
        sed -n '2,$ p' $file | awk '{for(i=3;i<=NF;++i){printf("%11.3E ",$i);} printf("\n");}' > "pdos.$i.$Counter_orbit"
        Counter_orbit=$(echo "$Counter_orbit + 1" | bc )
    done
    Counter_orbit=$(echo "$Counter_orbit - 1" | bc )
    # here Counter_orbit = MAX[orbital],

    #################################
    # prepare pdos.$i
    # Counter_orbit = 0 ==> s
    if [ $Counter_orbit == 0 ]
    then
        echo "Highest orbital is : s"
        echo "# E(eV)   s " > "pdos.$i"
    # Counter_orbit = 1 ==> p
    elif [ $Counter_orbit == 1 ]
    then
        echo "Highest orbital is : p"
        echo "# E(eV)   s               pz          px          py" > "pdos.$i"
    # Counter_orbit = 2 ==> d
    elif [ $Counter_orbit == 2 ]
    then
        echo "Highest orbital is : d"
        echo "# E(eV)   s               pz          px          py                dz2          dzx         dzy          dx2y2          dxy" > "pdos.$i"
    else
        echo "Sorry, we don't support f orbitals so far!"
        exit 111
    fi

   paste $File_Erange "./pdos.$i."* >> "pdos.$i"

   # paste "./pdos.$i."* >> "pdos.$i"
   
   rm -rf "./pdos.$i."*

done # atom loop