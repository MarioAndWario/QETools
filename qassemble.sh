#!/bin/bash
#This script will assemble the input files for QE into a ``QE.in'' file
cat IN.q CELL.q POT.q POS.q KP.q > QE.in