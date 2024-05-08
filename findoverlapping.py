import ipaddress
import json
import sys

def find_overlapping_cidrs(cidr_list):
    overlapping_cidrs = []

    for i in range(len(cidr_list)):
        for j in range(i+1, len(cidr_list)):
            cidr1 = ipaddress.ip_network(cidr_list[i]['cidr'])
            cidr2 = ipaddress.ip_network(cidr_list[j]['cidr'])

            if cidr1.overlaps(cidr2):
                overlapping_cidrs.append((i, j))

    return overlapping_cidrs

def remove_overlapping_cidrs(json_file, overlapping_cidrs):
    with open(json_file, 'r') as f:
        data = json.load(f)

    for pair in overlapping_cidrs:
        print(f"Overlapping CIDRs: {data[pair[1]]} deleted from json file")
        del data[pair[1]]
        

    with open(json_file, 'w') as f:
        json.dump(data, f, indent=4)


if __name__ == "__main__":
    # Check if JSON file name is provided as argument
    if len(sys.argv) != 2:
        print("Usage: python process_json.py <json_file>")
        sys.exit(1)

    # Assign the first argument (JSON file name) to json_file variable
    json_file = sys.argv[1]

    with open(json_file, 'r') as f:
        cidr_list = json.load(f)

    # Find overlapping CIDRs
    overlapping_cidrs = find_overlapping_cidrs(cidr_list)
    print("Overlapping CIDRs:")
    for pair in overlapping_cidrs:
        cidr1 = cidr_list[pair[0]]
        cidr2 = cidr_list[pair[1]]
        print(f"{cidr1['cidr']} overlaps with {cidr2['cidr']}")



    # Remove overlapping CIDRs from JSON file
    # remove_overlapping_cidrs(json_file, overlapping_cidrs)


