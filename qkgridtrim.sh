#!/bin/bash
cat ref | awk -F "=" '{print $2}' | awk -F "(" '{print $2}' | awk -F ")" '{print $1}' > coord.q