#!/bin/bash

# This scirpt only need to run when we setup ipam for the first time, this does not need to run periodically.

function add_spaces(){
    space=$1
    desc=$2
    ./function.sh post '{"name": "'"$space"'", "desc": "'"$desc"'"}' "/api/spaces"
    echo -e "\n"
}

function add_blocks(){
    space=$1
    block=$2
    cidr=$3
    ./function.sh post '{"name": "'"$block"'", "cidr": "'"$cidr"'"}' "/api/spaces/$space/blocks"
    echo -e "\n"
}

function setup(){

    # create space and  block
    env=$1
    desc="This space is for HMCTS $env blocks"
    add_spaces $env "$desc"

    block_10="$env""_10"
    cidr_10="10.0.0.0/8"
    add_blocks $env $block_10 $cidr_10

    block_172="$env""_172"
    cidr_172="172.0.0.0/8"
    add_blocks $env $block_172 $cidr_172

    block_163="$env""_163"
    cidr_163="163.0.0.0/8"
    add_blocks $env $block_163 $cidr_163

    block_198="$env""_198"
    cidr_198="198.0.0.0/8"
    add_blocks $env $block_198 $cidr_198

    block_192="$env""_192"
    cidr_192="192.0.0.0/8"
    add_blocks $env $block_192 $cidr_192

}

# SBOX create space and  block and associate vnets
setup "sbox"

# NONPROD create space and  block
setup "nonprod"

# PROD create space and  block
setup "prod"