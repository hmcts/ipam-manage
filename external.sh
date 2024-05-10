#!/bin/bash


function add_external_cidr() {
    space=$1
    block=$2
    startswith=$3
    output=$4
    vnet_file=$5

    # filtering the effective routes IPs with the appropriate CIDR starting with
    output_filter=$(echo "$output" | jq '[.[] | select(.addressPrefix[0] | startswith("'"$startswith"'"))]')
    echo $output_filter
    # convert the filtered data into format that ipam api accepts
    converted_output=$(echo "$output_filter" | jq -r 'to_entries | map({name: ("external" + (.key + 1 | tostring)), desc: .value.nextHopType, cidr: .value.addressPrefix[0]})')
    
    # Check if converted_output is not empty and is a valid JSON array with elements
    if [[ -n $converted_output && $converted_output != "[]" ]]; then

        filename="$space"".json"

        # copy data to json file
        echo "$converted_output" > $filename
        
        
        resource_ids=$(jq -r '.[]' $vnet_file)
        
        cidr_list=$(az network vnet show --ids $resource_ids --query "[].addressSpace.addressPrefixes")
        
        # call the python script to find the overlapping CIDRs and remove them from json file
        python3 findoverlapping.py $filename "$cidr_list"
        
        # call ipam API to add the external addresses
        ./function.sh put "$(cat $filename)"  "/api/spaces/$space/blocks/$block/externals"
        
        # delete the json file
        rm $filename
    else
        echo "No JSON data or empty array."
    fi


    echo -e "\n"
}

function run_env() {
    space=$1
    name=$2
    subscription=$3
    rg=$4
    vnet_file=$5

    az account set --subscription $subscription
    # getting all the effective routes from the NIC
    output=$(az network nic show-effective-route-table --name $name --resource-group $rg --query "value[?nextHopType=='VirtualNetworkGateway' && !contains(addressPrefix, '10.0.0.0/8')]")
    
    block_10="$space""_10"
    startswith_10="10."
    add_external_cidr "$space" "$block_10" "$startswith_10" "$output" "$vnet_file"

    block_172="$space""_172"
    startswith_172="172."
    add_external_cidr "$space" "$block_172" "$startswith_172" "$output" "$vnet_file"

    block_163="$space""_163"
    startswith_163="163."
    add_external_cidr "$space" "$block_163" "$startswith_163" "$output" "$vnet_file"


    block_198="$space""_198"
    startswith_198="198."
    add_external_cidr "$space" "$block_198" "$startswith_198" "$output" "$vnet_file"

    block_192="$space""_192"
    startswith_192="192."
    add_external_cidr "$space" "$block_192" "$startswith_192" "$output" "$vnet_file"
}
space="nonprod"
name="hmcts-hub-nonprodi-nic-transit-public-0"
subscription="HMCTS-HUB-NONPROD-INTSVC"
rg="hmcts-hub-nonprodi"
vnet_file="nonprod_vnets.json"

run_env "$space" "$name" "$subscription" "$rg" "$vnet_file"


space="prod"
name="hmcts-hub-prod-int-nic-transit-public-0"
subscription="HMCTS-HUB-PROD-INTSVC"
rg="hmcts-hub-prod-int"
vnet_file="prod_vnets.json"
run_env "$space" "$name" "$subscription" "$rg" "$vnet_file"