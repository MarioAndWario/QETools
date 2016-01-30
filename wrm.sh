#!/bin/bash
#!/bin/bash
QEinput="QE.in"
prefix=$(grep "prefix" ${QEinput} | awk -F"[']" '{print $2}')
echo "We are deleting wfn files for prefix = ${prefix} ..."
rm -f ${prefix}.wfc*
