import ipaddress
import json
import sys

def find_overlapping_cidrs(json_file, cidr_list):
    overlapping_cidrs = []

    with open(json_file, 'r') as f:
        data = json.load(f)
    
    # Iterate over the list in reverse order
    for i in range(len(data) - 1, 0, -1):
        cidr1 = ipaddress.ip_network(data[i]['cidr'])
        
        # Iterate over the previous elements
        for j in range(i):
            cidr2 = ipaddress.ip_network(data[j]['cidr'])

            if cidr1.overlaps(cidr2):
                overlapping_cidrs.append((i, j))
                
                print(f"{cidr1} overlaps with {cidr2}")

                if cidr1.prefixlen < cidr2.prefixlen:
                    print(f"Overlapping CIDRs: {data[j]} deleted from json file")
                    del data[j]
                    break  # Exit the inner loop after deleting the CIDR
                else:
                    print(f"Overlapping CIDRs: {data[i]} deleted from json file")
                    del data[i]
                    
    # Remove overlapping CIDRs from the internal vnet cidr_list
    if cidr_list != "":
        cidr_list_temp = json.loads(cidr_list)

        for sublist in cidr_list_temp:
            for cidr_string in sublist:
                
                cidr1 = ipaddress.ip_network(cidr_string)
                
                # Iterate over the JSON data
                for j in range(len(data)):
                    cidr2 = ipaddress.ip_network(data[j]['cidr'])

                    if cidr1.overlaps(cidr2):
                        print(f"{cidr1} VNET cidr overlaps with {cidr2} external in cidr_list")
                        print(f"Overlapping CIDRs: {data[j]} deleted from external json file")
                        # Remove the JSON object
                        del data[j]
                        break  # Exit the inner loop after deleting the JSON object


    with open(json_file, 'w') as f:
        json.dump(data, f, indent=4)
    
    return overlapping_cidrs


if __name__ == "__main__":
    # Check if JSON file name is provided as argument
    if len(sys.argv) != 3:
        print("Usage: python3 findoverlapping.py <json_file> <cidr_list>")
        sys.exit(1)

    # Assign the first argument (JSON file name) to json_file variable
    json_file = sys.argv[1]

    cidr_list = sys.argv[2]

    
    # Find overlapping CIDRs
    overlapping_cidrs = find_overlapping_cidrs(json_file,cidr_list)



