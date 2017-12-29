#!/bin/bash

# default directory is `../scf`
# -w$DIR/--wfn=$DIR : copy whole *.save file, including charge density file and wavefunctions
# -c$DIR/--chg=$DIR : only copy *.save file with charge density file
# -p$DIR/--pos=$DIR : only copy POS.q and CELL.q
# -i$DIR/--inp=$DIR : copy all input files: IN.q POS.q CELL.q KP.q POT.q subqe.sh

# ======
# read the options
# `getopt -o` followed by short options
# `getopt --long` followed by long options

# ======
# The set command takes any arguments after the options (here "--" signals the end of the options) and assigns them to the positional parameters ($0..$n). The eval command executes its arguments as a bash command.
# set -- "ab bc" will treat `"ab` as $1 and `bc$` as $2, (annoying whitespace problem!!!)
# eval set -- "ab bc" will treat `ab bc` as $1. By passing the set command to eval bash will honor the embedded quotes in the string rather than assume they are part of the word.
# '--' means no more options following (both set and getopt use it), and we can specify the input string, which is usually $@, which is an array of all the input argument in command line.
# ======
# shift n : moving current argument parameter (e.g. $4) to $(4-n)
# ======
# getopt just like a rearrangement of string

TEMP=`getopt -o hw::c::p::i:: --long --help,wfn::,chg::,pos::,inp:: -n 'Some errors!' -- "$@"`
#echo "${TEMP}"
eval set -- "$TEMP"

DIRname="../scf"

# extract options and their arguments into variables.
while true ; do
    DELflag="MW"
    case "$1" in
        -w|--wfn)
            case "$2" in
                "")
                    DIRname="../scf"
                    shift 2 ;;
                *)
                    DIRname=$2
                    shift 2 ;;
            esac
            prefix=$(grep "prefix" "${DIRname}/IN.q" | head -n 1 | awk -F"[']" '{print $2}')
            if [ ! -z $prefix ]; then
                if [ -d "./${prefix}.save" ]; then
                    echo "${prefix}.save exists! q: quit, d: delete ?"
                    read DELflag
                    if [ $DELflag .eq. "d" ]; then
                        echo "Remove ${prefix}.save"
                        rm -r ${prefix}.save
                    else
                        echo "Exit ..."
                        exit 2
                    fi
                fi
            fi
            echo "Copy ${prefix}.save from ${DIRname}"
            cp -r "${DIRname}/${prefix}.save" .
            ;;
        -c|--chg)
            case "$2" in
                "")
                    DIRname="../scf"
                    shift 2 ;;
                *)
                    DIRname=$2
                    shift 2 ;;
            esac
            prefix=$(grep "prefix" "${DIRname}/IN.q" | head -n 1 | awk -F"[']" '{print $2}')
            if [ ! -z $prefix ]; then
                if [ -d "./${prefix}.save" ]; then
                    echo "${prefix}.save exists! q: quit, d: delete ?"
                    read DELflag
                    if [ ${DELflag} == "d" ]; then
                        echo "Remove ${prefix}.save"
                        rm -r ${prefix}.save
                    else
                        echo "Exit ..."
                        exit 2;
                    fi
                fi
            fi
            mkdir "${prefix}.save"
            echo "Copy charge density file from ${DIRname}/${prefix}.save"
            cp "${DIRname}/${prefix}.save/charge-density.dat" "./${prefix}.save"

            # copy rho%ns or rho%ns_nc into current dir
            cp "${DIRname}/${prefix}.occup" "./"

            # copy magnetization files
            cp "${DIRname}/${prefix}.save/magnetization.x.dat" "./${prefix}.save"
            cp "${DIRname}/${prefix}.save/magnetization.y.dat" "./${prefix}.save"
            cp "${DIRname}/${prefix}.save/magnetization.z.dat" "./${prefix}.save"
            cp "${DIRname}/${prefix}.save/spin-polarization.dat" "./${prefix}.save"
            #
            cp "${DIRname}/${prefix}.save/data-file.xml" "./${prefix}.save"
            ;;
        -p|--pos)
            case "$2" in
                "")
                    DIRname="../relax"
                    shift 2 ;;
                *)
                    DIRname=$2
                    shift 2 ;;
            esac
            echo "Copy POS.final.q/CELL.final.q from ${DIRname}"
            cp "${DIRname}/POS.final.q" .
            cp "${DIRname}/CELL.final.q" .
            ;;
        -i|--inp)
            case "$2" in
                "")
                    DIRname="../scf"
                    shift 2 ;;
                *)
                    DIRname=$2
                    shift 2 ;;
            esac
            if [ -f IN.q ] || [ -f KP.q ] || [ -f POS.q ] || [ -f POT.q ] || [ -f CELL.q ] || [ -f subqe.sh ]; then
                echo "Input files exists! q: quit, o: overwrite ?"
                read DELflag
                if [ ${DELflag} == "o" ]; then
                    echo "Overwrite input files *.q !"
                else
                    echo "Exit ..."
                    exit 2;
                fi
            fi
            echo "Copy IN.q KP.q POS.q POT.q CELL.q from ${DIRname}"
            cp "${DIRname}/IN.q" .
            cp "${DIRname}/KP.q" .
            cp "${DIRname}/POS.q" .
            cp "${DIRname}/POT.q" .
            cp "${DIRname}/CELL.q" .
            cp "${DIRname}/subqe.sh" .
            ;;
        -h)
            shift
            echo "Usage: qcp.sh -w\$DIR/-wfn=\$DIR : cp -r $DIR/*.save . (default ../scf)"
            echo "              -c\$DIR/-chg=\$DIR : only copy charge density from $DIR (default ../scf)"
            echo "              -p\$DIR/-pos=\$DIR : copy POS.final.q or/and CELL.final.q from $DIR(default ../relax)"
            echo "              -i\$DIR/-inp=\$DIR : copy $DIR:*.q . (default ../scf)"

            break ;;
        --)
            # echo "Usage: qcp.sh -w\$DIR/-wfn=\$DIR : cp -r $DIR/*.save . (default ../scf)"
            # echo "              -c\$DIR/-chg=\$DIR : only copy charge density from $DIR (default ../scf)"
            # echo "              -p\$DIR/-pos=\$DIR : copy POS.final.q or/and CELL.final.q from $DIR(default ../relax)"
            # echo "              -i\$DIR/-inp=\$DIR : copy $DIR:*.q . (default ../scf)"
            exit 1 ;;
    esac
done

