#!/bin/bash


status=$(./function.sh get '' "/api/status")

function block_name() {
    space=$1
    prefix=$2

    if [[ "$prefix" == 10* ]]; then
        echo "$space""_10"
    elif [[ "$prefix" == 172* ]]; then
        echo "$space""_172"
    elif [[ "$prefix" == 163* ]]; then
        echo "$space""_163"
    elif [[ "$prefix" == 198* ]]; then
        echo "$space""_198"
    elif [[ "$prefix" == 192* ]]; then
        echo "$space""_192"
    else
        echo "Unknown Prefix : $prefix"
    fi

}

if [[ -z $status ]]; then
    echo "Cannot connect to IPAM apis!"
else
    json_data=$(./function.sh get '' "/api/spaces/sbox/blocks/sbox_10/available?expand=true")

    echo "$json_data" | jq -c '.[]' | while read -r vnet; do
        name=$(echo "$vnet" | jq -r '.name')
        id=$(echo "$vnet" | jq -r '.id')
        prefixes=$(echo "$vnet" | jq -r '.prefixes[]')

        # Check for 'sbox' or 'sandbox' in the name
        if [[ "$name" =~ sbox|sandbox ]]; then
            echo "Sandbox environment detected: $name"
            space="sbox"

            for prefix in $prefixes; do
                echo "Working with prefix: $prefix"
                block_name=$(block_name $space $prefix)
                
                existing_associated_vnets=$(./function.sh get '' "/api/spaces/$space/blocks/$block_name/networks")
                
                if [[ "$existing_associated_vnets" =~ $id ]]; then
                    echo "$id  already associated"
                else 
                    echo "Associate: $id  "
                fi
                # call the function to associate vnet with block, it will only associate if its not overlapping
                # ./function.sh post '{"id": "'"$id"'", "active": true}' "/api/spaces/$space/blocks/$block_name/networks"
                    
                echo -e "\n"
            done
            echo -e "\n"

        # Check for 'prod' in the name
        elif [[ "$name" =~ prod|ptl ]] && [[ ! "$name" =~ nonprod ]]; then
            echo "Production environment detected: $name"
            echo -e "\n"
        # Default case
        else
            echo "Other environment detected: $name"
            echo -e "\n"
        fi

        
  
    done

fi