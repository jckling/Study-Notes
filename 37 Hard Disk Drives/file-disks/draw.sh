#!/bin/bash

for i in {1..1000};
do
    tmp=($(./disk.py -a -1 -A 1000,-1,0 -w ${i} -p SATF -c | grep TOTALS | grep -Eo '[0-9]+'))
    $(printf "%s " ${i} >> data)
    $(printf "%s " "${tmp[@]}" >> data)
    $(echo >> data)
done