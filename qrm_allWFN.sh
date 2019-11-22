#!/bin/bash
#This script will recursively delete every prefix.wfc*, prefix.igk* and prefix.save/K* in current directory.

find . -type d \( ! -iname "K*" \) -exec qrm.sh -w{} \;
