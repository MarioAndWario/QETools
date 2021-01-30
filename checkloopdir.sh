#!/bin/bash
# This script check whether a job has finished successfully
if [ $# -ne 2 ]; then
    echo "Usage checkloopdir.sh [dir_header] [output_file] "
    exit 123
else
    dir_header=$1
    output_file=$2
    echo "dir_header = ${dir_header}"
    echo "output_file = ${output_file}"
fi

for dir in ./${dir_header}*
do
    echo "Enter $dir"
    cd $dir

    if [ -f "${output_file}" ]; then
        if [ "$(grep "JOB DONE." ${output_file})" ]; then
            echo "${output_file} in $dir finished."
        elif [ "$(grep "TOTAL:" ${output_file})" ]; then
            echo "${output_file} in $dir finished."
	else
	    echo "[WARNING] $output_dir in $dir not finished."	    
        fi
    else
       echo "[WARNING] $output_dir in $dir not existing."
    fi
    
    cd ..
    echo "==============="
done
