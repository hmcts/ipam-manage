#!/bin/bash

token=$(az account get-access-token --resource=api://3fa0259b-86c8-4cd7-bd2a-e5ab28625fe7 --query accessToken --output tsv)


# SBOX create space and  blcok
space="hmcts_sbox"
./function.sh post $token '{"name": "'"$space"'", "desc": "This space is for HMCTS sandbox blocks"}' "/api/spaces"
block1="hmcts_sbox"
./function.sh post $token '{"name": "'"$block1"'", "cidr": "10.0.0.0/8"}' "/api/spaces/$space/blocks"

json_data=$(<sbox_vnets.json)

./function.sh put $token "$json_data" "/api/spaces/$space/blocks/$block1/networks"

# NONPROD create space and  blcok
space="hmcts_nonprod"
./function.sh post $token '{"name": "'"$space"'", "desc": "This space is for HMCTS nonprod blocks"}' "/api/spaces"
# create blocks of cidr
block1="hmcts_nonprod"
./function.sh post $token '{"name": "'"$block1"'", "cidr": "10.0.0.0/8"}' "/api/spaces/$space/blocks"


# PROD create space and  blcok
space="hmcts_prod"
./function.sh post $token '{"name": "'"$space"'", "desc": "This space is for HMCTS prod blocks"}' "/api/spaces"
# create blocks of cidr
block1="hmcts_prod"
./function.sh post $token '{"name": "'"$block1"'", "cidr": "10.0.0.0/8"}' "/api/spaces/$space/blocks"



'[
    "/subscriptions/ea3a8c1e-af9d-4108-bc86-a7e2d267f49c/resourceGroups/hmcts-hub-sbox-int/providers/Microsoft.Network/virtualNetworks/hmcts-hub-sbox-int",
    "/subscriptions/ea3a8c1e-af9d-4108-bc86-a7e2d267f49c/resourceGroups/panorama-sbox-uks-rg/providers/Microsoft.Network/virtualNetworks/panorama-sbox-uks-vnet",
    "/subscriptions/ea3a8c1e-af9d-4108-bc86-a7e2d267f49c/resourceGroups/pkr-Resource-Group-mbjbuyjs7k/providers/Microsoft.Network/virtualNetworks/pkrvnmbjbuyjs7k",
    "/subscriptions/ea3a8c1e-af9d-4108-bc86-a7e2d267f49c/resourceGroups/private-dns-resolver-uksouth-sbox-int/providers/Microsoft.Network/virtualNetworks/private-dns-resolver-uksouth-vnet-sbox-int"
]'