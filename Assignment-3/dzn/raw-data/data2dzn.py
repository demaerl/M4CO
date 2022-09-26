import json
import sys
import argparse
import math
import os

if sys.version_info[0] < 3:
  raise Exception("Python 3 or a more recent version is required.")


def main():
    parser = argparse.ArgumentParser(prog="python3 data2dzn.py")
    parser.add_argument("inputFile", help="Input json file")

    args = parser.parse_args()
    print("Parsing: ", args.inputFile)
    
    outputFile = os.path.splitext(args.inputFile)[0] + ".dzn"

    output = open(outputFile, "w")
    data = open(args.inputFile, "r")
    dataJSON = json.load(data)

    nScooters = len(dataJSON['scooters'])
    nEmployees = len(dataJSON['employees'])

    # All nodes for computing distance matrix.
    allNodes = []
    # Min number of scooters that an employee wants to pick up.
    minNumScooters = []
    # Max number of scooters that an employee can pick up.
    maxNumScooters = []
    # Max distance that a employee is willing to travel.
    maxDist = []
    # The value for the company that this scooter is picked up.
    companyValue = []
    # The value for an employee to pick up this scooter.
    serviceValue = []

    print("Generating " + outputFile)

    for scooter in dataJSON['scooters']:
        allNodes.append((scooter['x'], scooter['y']))
        companyValue.append(scooter['company_value'])
        serviceValue.append(scooter['service_value'])

    for employee in dataJSON['employees']:
        allNodes.append((employee['current_x'], employee['current_y']))
        minNumScooters.append(employee['min_num_scooters'])
        maxNumScooters.append(employee['max_num_scooters'])
        maxDist.append(employee['max_dist'])

    # add home nodes.
    for employee in dataJSON['employees']:
        allNodes.append((employee['home_x'], employee['home_y']))

    distanceMatrix = []
    node1Idx = 1
    for node1 in allNodes:
        nodeDist = []
        node1Idx += 1
        node2Idx = 1
        for node2 in allNodes:
            node2Idx += 1
            if node1Idx > nScooters and node2Idx > nScooters:
                # Going directly from a start to an end node has no distance
                # as this just means that the employee was not used.
                # Going from an end node to a start node also has no distance.
                nodeDist.append(0)
            else:
                nodeDist.append(
                    math.ceil(math.sqrt((node1[0] - node2[0])**2 + (node1[1] - node2[1])**2)))
        distanceMatrix.append(nodeDist)

    output.write("nScooters \t= " + str(nScooters) + ";\n")
    output.write("nEmployees \t= " + str(nEmployees) + ";\n")
    output.write("dummy \t= " + str(nEmployees+1) + ";\n")
    output.write("TravelTime \t= [")
    for row in distanceMatrix:
        output.write("|" + str(row).strip("[]") + "\n")
    output.write("|];\n")
    output.write("Priority = " + str(companyValue) + ";\n")
    output.write("Payment = " + str(serviceValue) + ";\n")
    output.write("MinNumScooters = " + str(minNumScooters) + ";\n")
    output.write("MaxNumScooters = " + str(maxNumScooters) + ";\n")
    output.write("MaxTime = " + str(maxDist) + ";\n")
    output.write("alpha = 7;\n")
    output.write("beta = 1;\n")
    output.write("gamma = 13;\n")
    output.close()

    print("Done")


if __name__ == "__main__":
    main()
