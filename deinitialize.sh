#!/bin/bash

machines=(
  kafka-base
  kafka-tester
)

for machine in ${machines[@]}
do 
  machinectl stop ${machine}
done

while read -r machine
do
  machine=$(echo ${machine} | awk '{print $1}')
  echo "'${machine}'"
  machines+=(${machine})
  machinectl stop ${machine}
done < <(machinectl  list-images | grep kafka-node)

sleep 5

# Remove
for machine in ${machines[@]}
do 
  machinectl remove ${machine}
done

exit 0
