#!/bin/bash


function add_external_cidr() {
    space=$1
    name=$2
    rg=$3
    block=$4
    startswith=$5
    subscription=$6

    az account set --subscription $subscription
    output=$(az network nic show-effective-route-table --name $name --resource-group $rg --query "value[?nextHopType=='VirtualNetworkGateway']")

    output_filter=$(echo "$output" | jq '[.[] | select(.addressPrefix[0] | startswith("'"$startswith"'"))]')

    converted_output=$(echo "$output_filter" | jq -r 'to_entries | map({name: ("external" + (.key + 1 | tostring)), desc: .value.nextHopType, cidr: .value.addressPrefix[0]})')
    filename="$space"".json"
    echo "$converted_output" > $filename
    echo "$converted_output" > not_deleted.json
    python3 findoverlapping.py $filename
    ./function.sh put "$(cat $filename)"  "/api/spaces/$space/blocks/$block/externals"
    echo -e "\n"
}

space="nonprod"
name="hmcts-hub-nonprodi-nic-mgmt-0"
subscription="HMCTS-HUB-NONPROD-INTSVC"
rg="hmcts-hub-nonprodi"

block_10="nonprod_10"
startswith_10="10."
add_external_cidr "$space" "$name" "$rg" "$block_10" "$startswith_10" "$subscription"

# block="nonprod_172"
# startswith="172."
# add_external_cidr "$space" "$name" "$rg" "$block" "$startswith" "$subscription"