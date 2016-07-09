#!/bin/bash

# default directory is `.`
# -a$DIR/--all=$DIR : rm all output files
# -w$DIR/--wfn=$DIR : rm wfn in *.save directory
# -l$DIR/--log=$DIR : rm log files

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

TEMP=`getopt -o ha::W::w::l:: --long --help,all::,wfn::,wfc::,log:: -n 'Some errors!' -- "$@"`
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
            prefix=$(grep "prefix" "${DIRname}/IN.q" | awk -F"[']" '{print $2}')
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
            prefix=$(grep "prefix" "${DIRname}/IN.q" | awk -F"[']" '{print $2}')
            if [ ! -z $prefix ]; then
                if [ -d "./${prefix}.save" ]; then
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
            prefix=$(grep "prefix" "${DIRname}/IN.q" | awk -F"[']" '{print $2}')
            rm -rf ${DIRname}/${prefix}.wfc*
            rm -rf ${DIRname}/${prefix}.mix*
            rm -rf ${DIRname}/${prefix}.igk*
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
        -h)
            shift
            echo "Usage: qcp.sh -a\$DIR/-all=\$DIR : rm all output files (default ./)"
            echo "              -w\$DIR/-wfn=\$DIR : rm all wfns files (default ./)"
            echo "              -l\$DIR/-log=\$DIR : rm all log files (default ./)"

            break ;;
        --)
            # echo "Usage: qcp.sh -w\$DIR/-wfn=\$DIR : cp -r $DIR/*.save . (default ../scf)"
            # echo "              -c\$DIR/-chg=\$DIR : only copy charge density from $DIR (default ../scf)"
            # echo "              -p\$DIR/-pos=\$DIR : copy POS.final.q or/and CELL.final.q from $DIR(default ../relax)"
            # echo "              -i\$DIR/-inp=\$DIR : copy $DIR:*.q . (default ../scf)"
            exit 1 ;;
    esac
done

