# IPAM

https://ipam.hmcts.net/

Azure IPAM was developed to give customers a simple, straightforward way to manage their IP address space in Azure. It enables end-to-end planning, deploying, managing and monitoring of your IP address space, with an intuitive user experience. Additionally, it can automatically discover IP address utilization within your Azure tenant and enables you to manage it all from a centralized UI. You can also interface with the Azure IPAM service programmatically via a RESTful API to facilitate IP address management at scale via Infrastructure as Code (IaC) and CI/CD pipeline.

More info available here - https://azure.github.io/ipam/#/README 

## Build Status

|             | status |
|-------------|------------|
| **master** | [![Build Status](https://dev.azure.com/hmcts/DevOps/_apis/build/status/IPAM%20management?branchName=master)](https://dev.azure.com/hmcts/DevOps/_build?definitionId=980) |
| **Sync Vnets & External Routes** | [![Build Status](https://dev.azure.com/hmcts/DevOps/_apis/build/status/IPAM%20-%20Sync%20External%20CIDRs?branchName=master)](https://dev.azure.com/hmcts/DevOps/_build?definitionId=979) |

The Sync Vnets & External Routes pipeline is set to run every day at 3AM so that data is always up to date. Whenever new vnet is added to any environment, the pipeline will pick it automatically overnight and associate it with relevant environment block.


## Setup

On the IPAM setup, we have 3 spaces (`sbox`, `nonprod` and `prod`) and each space has different blocks for different CIDR space. E.g. `sbox` space has `sbox_10` block which means it has CIDR range of `10.0.0.0/8`. Similarly `sbox_192` block has space of `192.0.0.0/8`.

We have configured ranges starting from `10.`,`163.`,`172.`,`192.` and `198.`  for each environment blocks.

You will need name of the space and block when you are querying APIs.

## APIs

In order to access the IPAM apis, you will need to make sure you are **connected to the F5 VPN** or you can access from the internal VMs e.g. `bastion-prod
`
To access the APIs, this is the base URL to use - https://ipam.hmcts.net/  and then you can select which API you would like to access from this document list here - https://ipam.hmcts.net/api/docs

**Please note that the Docs portal doesn't allow you to make API calls at the moment and its known problem with Azure IPAM developer team**

### API example with Postman

Below is example of `/api/tools/nextAvailableVNet` using Postman.  This API allow us to find next available Vnet space.

Get the Token after you logged in to the [IPAM portal](https://ipam.hmcts.net/)

<img src=images/token.png width="400">

On the Postman, depending up which api you are using, choose the method,  Post, Get, Put etc.

And then, select Bearer Token in Authorization and paste your above copied token there.

<img src=images/token-2.png width="400">

In the Body section, select Raw and Json type.   You can then copy the body data from the [IPAM API Docs](https://ipam.hmcts.net/api/docs#/tools/next_available_vnet_api_tools_nextAvailableVNet_post) and paste it in the body.  Replace the values depending upon the size and in the environment you are looking to find nextAvailable VNet space.

<img src=images/body-ipam-api.png width="400">

### API example with Shell commands

Below is example of `/api/tools/nextAvailableVNet` using Shell commands.

```bash
bearer_token=$(az account get-access-token --resource=api://3fa0259b-86c8-4cd7-bd2a-e5ab28625fe7 --query accessToken --output tsv)
json_body='{
  "space": "prod",
  "blocks": [
    "prod_10"
  ],
  "size": 22,
  "reverse_search": false,
  "smallest_cidr": false
}'
url="https://ipam.hmcts.net/api/tools/nextAvailableVNet"

curl -X POST -H "Authorization: Bearer $bearer_token" -H "Content-Type: application/json" -d "$json_body" "$url"
```