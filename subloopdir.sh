#!/bin/bash
# This script submits a series of scripts in the directories starting with $dir_header
if [ $# -ne 2 ]; then
    echo "Usage loopdir.sh [dir_header] [script] "
    exit 123
else
    dir_header=$1
    script=$2
    echo "dir_header = ${dir_header}"
    echo "script = ${script}"
fi

for dir in ./${dir_header}*
do
    echo "Enter $dir"
    cd $dir
    echo "sbatch ${script}"
    sbatch ${script}
    cd ..
    echo "==============="
done
