#!/bin/bash

function add_external_cidr() {
    space=$1
    block=$2
    startswith=$3
    output=$4
    vnet_data="$5"

    # filtering the effective routes IPs with the appropriate CIDR starting with
    output_filter=$(echo "$output" | jq '[.[] | select(.addressPrefix[0] | startswith("'"$startswith"'"))]')
    
    # convert the filtered data into format that ipam api accepts
    converted_output=$(echo "$output_filter" | jq -r 'to_entries | map({name: ("external" + (.key + 1 | tostring)), desc: .value.nextHopType, cidr: .value.addressPrefix[0]})')
    
    # Check if converted_output is not empty and is a valid JSON array with elements
    if [[ -n $converted_output && $converted_output != "[]" ]]; then

        filename="$space"".json"

        # copy data to json file
        echo "$converted_output" > $filename
        
        resource_ids=$(echo "$vnet_data" | jq -r '.[]')
        
        if [[ -z $resource_ids ]]; then
            cidr_list=""
        else
            cidr_list=$(az network vnet show --ids $resource_ids --query "[].addressSpace.addressPrefixes")            
        fi

        echo $cidr_list
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

    az account set --subscription $subscription
    # getting all the effective routes from the NIC
    output=$(az network nic show-effective-route-table --name $name --resource-group $rg --query "value[?nextHopType=='VirtualNetworkGateway' && !contains(addressPrefix, '10.0.0.0/8')]")
    
    block_10="$space""_10"
    
    # Define the YAML path for the subnets
    yaml_space=".""$space"".subnets[]"

    # Fetching the externals for the block_10
    externals_json=$(./function.sh get '' "/api/spaces/$space/blocks/$block_10/externals")

    # Loop through each subnet in the YAML file
    yq -o=json $yaml_space interim-hosting.yaml | jq -c '.' | while read -r subnet; do

        yaml_cidr=$(echo "$subnet" | yq '.cidr')
        yaml_name=$(echo "$subnet" | yq '.name')
        yaml_desc=$(echo "$subnet" | yq '.desc')

        # Filter the externals JSON to find matching CIDRs
        matching_externals=$(echo "$externals_json" | jq -c --arg cidr "$yaml_cidr" '[.[] | select(.cidr == $cidr)]')
        
        # If matching externals exist, patch them; otherwise, create a new external
        if [[ $(echo "$matching_externals" | jq 'length') -gt 0 ]]; then
            api_name=$(echo "$matching_externals" | jq -r '.[0].name')
            patch_payload=$(jq -n \
              --arg name "$yaml_name" \
              --arg desc "$yaml_desc" \
              '[{"op":"replace","path":"/name","value":$name},{"op":"replace","path":"/desc","value":$desc}]')
            ./function.sh patch "$patch_payload" "/api/spaces/$space/blocks/$block_10/externals/$api_name"       
        else # Create a new external if it doesn't exist
            post_payload=$(jq -n \
              --arg name "$yaml_name" \
              --arg desc "$yaml_desc" \
              --arg cidr "$yaml_cidr" \
              '{name: $name, desc: $desc, cidr: $cidr}')
            result=$(./function.sh post "$post_payload" "/api/spaces/$space/blocks/$block_10/externals")
        fi
        
    done # End of loop through subnets yaml file

    vnet_data=""

    vnet_data=$(./function.sh get '' "/api/spaces/$space/blocks/$block_10/available")
    startswith_10="10."
    add_external_cidr "$space" "$block_10" "$startswith_10" "$output" "$vnet_data"

    block_172="$space""_172"
    vnet_data=$(./function.sh get '' "/api/spaces/$space/blocks/$block_172/available")
    startswith_172="172."
    add_external_cidr "$space" "$block_172" "$startswith_172" "$output" "$vnet_data"

    block_163="$space""_163"
    vnet_data=$(./function.sh get '' "/api/spaces/$space/blocks/$block_163/available")
    startswith_163="163."
    add_external_cidr "$space" "$block_163" "$startswith_163" "$output" "$vnet_data"

    block_198="$space""_198"
    vnet_data=$(./function.sh get '' "/api/spaces/$space/blocks/$block_198/available")
    startswith_198="198."
    add_external_cidr "$space" "$block_198" "$startswith_198" "$output" "$vnet_data"

    block_192="$space""_192"
    vnet_data=$(./function.sh get '' "/api/spaces/$space/blocks/$block_192/available")
    startswith_192="192."
    add_external_cidr "$space" "$block_192" "$startswith_192" "$output" "$vnet_data"
}

space="nonprod"
name="hmcts-hub-nonprodi-nic-transit-public-0"
subscription="HMCTS-HUB-NONPROD-INTSVC"
rg="hmcts-hub-nonprodi"

run_env "$space" "$name" "$subscription" "$rg"


space="prod"
name="hmcts-hub-prod-int-nic-transit-public-0"
subscription="HMCTS-HUB-PROD-INTSVC"
rg="hmcts-hub-prod-int"

run_env "$space" "$name" "$subscription" "$rg"