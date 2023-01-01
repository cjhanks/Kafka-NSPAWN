#!/bin/bash

machines=(
  kafka-base
  kafka-node1
  kafka-node2
  kafka-node3
  kafka-tester
)

for machine in ${machines[@]}
do 
  machinectl stop   ${machine}
done

sleep 5
  
for machine in ${machines[@]}
do 
  machinectl remove ${machine}
done

exit 0
