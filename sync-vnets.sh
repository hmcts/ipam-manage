#!/bin/bash

function process_prefixes() {
        space=$1
        prefixes="$2"
        block_name=$3

        for prefix in $prefixes; do
                
                existing_associated_vnets=$(./function.sh get '' "/api/spaces/$space/blocks/$block_name/networks")
                
                if [[ "$existing_associated_vnets" =~ $id ]]; then
                    echo "$id  already associated"
                else 
                    echo "Associate: $id  "
                    # call the function to associate vnet with block, it will only associate if its not overlapping
            
                    ./function.sh post '{"id": "'"$id"'", "active": true}' "/api/spaces/$space/blocks/$block_name/networks"
                fi                    
                echo -e "\n"
        done
}

function call_json_config() {
    space=$1
    subscriptions=$2

    block="$space""_10"
    ./reservations.sh "$space" "$block"
    json_config $space $block "$subscriptions"
    
    block="$space""_172"
    ./reservations.sh "$space" "$block"
    json_config $space $block "$subscriptions"

    block="$space""_163"
    ./reservations.sh "$space" "$block"
    json_config $space $block "$subscriptions"

    block="$space""_198"
    ./reservations.sh "$space" "$block"
    json_config $space $block "$subscriptions"

    block="$space""_192"
    ./reservations.sh "$space" "$block"
    json_config $space $block "$subscriptions"


}

function json_config() {
    space=$1
    block=$2
    subscriptions=$3
    
    json_data=$(./function.sh get '' "/api/spaces/$space/blocks/$block/available?expand=true")

    echo "$json_data" | jq -c '.[]' | while read -r vnet; do
        name=$(echo "$vnet" | jq -r '.name' | tr '[:upper:]' '[:lower:]')
        id=$(echo "$vnet" | jq -r '.id')
        prefixes=$(echo "$vnet" | jq -r '.prefixes[]')
        subscription_id=$(echo "$vnet" | jq -r '.subscription_id')

        subscription_name=$(echo "$subscriptions" | jq -r '.[] | select(.id == "'$subscription_id'") | .name' | tr '[:upper:]' '[:lower:]')

        # Check for 'sbox' or 'sandbox' in the name
        if [[ "$space" == sbox ]] && { [[ "$name" =~ (sbox|sandbox) ]] || [[ "$subscription_name" =~ (sbox|sandbox) ]]; }; then
            echo "Sandbox environment detected: $name"
            process_prefixes $space "$prefixes" $block
        # Check for 'prod' in the name
        elif [[ "$space" == prod ]] && { [[ "$name" =~ (prod|ptl) ]] || [[ "$subscription_name" =~ (prod|ptl) ]]; } && [[ ! "$name" =~ nonprod ]] && [[ ! "$name" =~ ptlsbox ]]; then
            echo "Production environment detected: $name"
            process_prefixes $space "$prefixes" $block
        # Check for 'nonprod' in the name and ignore anything with sbox,prod and ptl
        elif [[ "$space" == nonprod ]] && [[ ! "$name" =~ (sbox|sandbox|ptl) ]] && [[ ! "$subscription_name" =~ (sbox|sandbox|ptl) ]]; then
            echo "NonProd environment detected: $name"
            process_prefixes $space "$prefixes" $block
        fi  
    done
}

status=$(./function.sh get '' "/api/status")


if [[ -z $status ]]; then
    echo "Cannot connect to IPAM apis!"
else

    subscriptions=$(az account list --query "[].{name:name,id:id}")
    call_json_config "sbox" "$subscriptions"

    call_json_config "prod" "$subscriptions"

    call_json_config "nonprod" "$subscriptions"
    
fi