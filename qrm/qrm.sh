#!/bin/bash

# default directory is `.`
# -a$DIR/--all=$DIR : rm all output files
# -w$DIR/--wfn=$DIR : rm wfn in *.save directory
# -l$DIR/--log=$DIR : rm log files
# -e$DIR/--eig=$DIR : rm eigenvalue and helper files
# -s$DIR/--save=$DIR : rm prefix.save directory in dos, pdos, ldos calculations
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


TEMP=`getopt -o ha::W::w::l::e::s:: --long --help,all::,wfn::,wfc::,log::,eig::,save:: -n 'Some errors!' -- "$@"`
#echo "${TEMP}"
eval set -- "$TEMP"

DIRname="."

# extract options and their arguments into variables.
while true ; do
    DELflag="MW"
    case "$1" in
        -a|--all)
            case "$2" in
                "")
                    DIRname="."
                    shift 2 ;;
                *)
                    DIRname=$2
                    shift 2 ;;
            esac
            if [ -f ${DIRname}/QE.in ]; then
                prefix=$(grep "prefix" "${DIRname}/QE.in" | awk -F"[']" '{print $2}')
            elif [ -f ${DIRname}/IN.q ]; then
                prefix=$(grep "prefix" "${DIRname}/IN.q" | awk -F"[']" '{print $2}')
            else
                echo "--- No input file in ${DIRname}"
                exit
            fi
            rm -rf ${DIRname}/JOB.*
            rm -rf ${DIRname}/slurm*
            rm -rf ${DIRname}/${prefix}.save
            ;;
        -W|--wfn)
            case "$2" in
                "")
                    DIRname="."
                    shift 2 ;;
                *)
                    DIRname=$2
                    shift 2 ;;
            esac

########
#Decide wether or not to carry on based on if there is IN.q in current directory
            if [ -f ${DIRname}/QE.in ]; then
                echo "+++ Found PW input file in ${DIRname}"
                prefix=$(grep "prefix" "${DIRname}/QE.in" | awk -F"[']" '{print $2}')
            elif [ -f ${DIRname}/IN.q ]; then
                echo "+++ Found PW input file in ${DIRname}"
                prefix=$(grep "prefix" "${DIRname}/IN.q" | awk -F"[']" '{print $2}')
            else
                echo "--- No PW (-W) input file in ${DIRname}"
                continue
            fi
########
            # echo "prefix = ${prefix}"
            if [ ! -z ${prefix} ]; then
                if [ -d "${DIRname}/${prefix}.save" ]; then
                    echo "+++ Deleting WFNDir K* in ${DIRname}/${prefix}.save"
                    rm -rf ${DIRname}/${prefix}.save/K*
                fi
            fi
            ;;
        -w|--wfc)
            case "$2" in
                "")
                    DIRname="."
                    shift 2 ;;
                *)
                    DIRname=$2
                    shift 2 ;;
            esac

            if [ -f ${DIRname}/QE.in ]; then
                echo "+++ Found PW input file in ${DIRname}"
                prefix=$(grep "prefix" "${DIRname}/QE.in" | awk -F"[']" '{print $2}')
            elif [ -f ${DIRname}/IN.q ]; then
                echo "+++ Found PW input file in ${DIRname}"
                prefix=$(grep "prefix" "${DIRname}/IN.q" | awk -F"[']" '{print $2}')
            else
                echo "--- No PW (-w) input file in ${DIRname}"
                continue
            fi
            echo "+++ Deleting WFNfile ${prefix}.wfc* in ${DIRname}"
            rm -rf ${DIRname}/${prefix}.wfc*
            rm -rf ${DIRname}/${prefix}.mix*
            rm -rf ${DIRname}/${prefix}.igk*
            ;;
        -s|--save)
            case "$2" in
                "")
                    DIRname="."
                    shift 2 ;;
                *)
                    DIRname=$2
                    shift 2 ;;
            esac

            if [ -f "${DIRname}/dos.in" ]; then
                echo "+++ Found DOS input file in ${DIRname}"
                prefix=$(grep "prefix" "${DIRname}/dos.in" | awk -F"[']" '{print $2}')
            elif [ -f ${DIRname}/pp.in ]; then
                echo "+++ Found LDOS input file in ${DIRname}"

                prefix=$(grep "prefix" "${DIRname}/pp.in" | awk -F"[']" '{print $2}')
            elif [ -f ${DIRname}/projwfc.in ]; then
                echo "+++ Found PDOS input file in ${DIRname}"
                prefix=$(grep "prefix" "${DIRname}/projwfc.in" | awk -F"[']" '{print $2}')
            else
                echo "--- No DOS input file in ${DIRname}"
                continue
            fi

            if [ -d ${DIRname}/${prefix}.save ]; then
                echo "+++ Deleting ${prefix}.save in ${DIRname} ->"
                rm -rf ${DIRname}/${prefix}.save
            fi
            ;;
        -l|--log)
            case "$2" in
                "")
                    DIRname="."
                    shift 2 ;;
                *)
                    DIRname=$2
                    shift 2 ;;
            esac
            rm -rf ${DIRname}/JOB.*
            rm -rf ${DIRname}/slurm-*
            ;;
        -e|--eig)
            case "$2" in
                "")
                    DIRname="."
                    shift 2 ;;
                *)
                    DIRname=$2
                    shift 2 ;;
            esac
            rm -rf ${DIRname}/eigenvalue*
            rm -rf ${DIRname}/Klength.dat
            rm -rf ${DIRname}/helper*
            rm -rf ${DIRname}/tempEig.dat
            rm -rf ${DIRname}/Eig.*
            ;;
        -h)
            shift
            echo "Usage: qcp.sh -a\$DIR/-all=\$DIR : rm all output files (default ./)"
            echo "              -w\$DIR/-wfc=\$DIR : rm all wfns files (default ./)"
            echo "              -l\$DIR/-log=\$DIR : rm all log files (default ./)"
            echo "              -s\$DIR/-save=\$DIR : rm prefix.save directory in dos, ldos, pdos calcualtions (default ./)"
            echo "              -W\$DIR/-wfn=\$DIR : rm prefix.save/K* directories (default ./)"

            break
            ;;
        --)
            shift
            echo "----------------------------------------------"
#             echo "Usage: qcp.sh -a\$DIR/-all=\$DIR : rm all output files (default ./)"
#             echo "              -w\$DIR/-wfc=\$DIR : rm all wfns files (default ./)"
#             echo "              -l\$DIR/-log=\$DIR : rm all log files (default ./)"
#             echo "              -s\$DIR/-save=\$DIR : rm prefix.save directory in dos, ldos, pdos calcualtions (default ./)"
#             echo "              -W\$DIR/-wfn=\$DIR : rm prefix.save/K* directories (default ./)"
            exit 0
            ;;
    esac
done

