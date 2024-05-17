#!/bin/bash
# set -ex

# delete all the reservations to able to sync vnets

space=$1
block=$2

reservation_data=$(./function.sh get '' "/api/spaces/$space/blocks/$block/reservations")

echo "reservation_data: $reservation_data"
if [[ -n $reservation_data ]] && [[ $(echo $reservation_data | jq '. | length') -gt 0 ]]; then
    
  echo $reservation_data | jq -r '.[] | .id' | while read id; do
    echo "Processing ID: $id"
    ./function.sh delete '["'$id'"]' "/api/spaces/$space/blocks/$block/reservations"
  done

else
  echo "No valid reservation data found or data is not in JSON format."
fi