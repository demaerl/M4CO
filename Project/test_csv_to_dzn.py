import csv
import os
from pymzn import dzn

def read_csv(filename: str):
    data = {}
    data['Preference'] = []
    with open(filename, 'r') as csv_file:
        csv_reader = csv.reader(csv_file, delimiter=',')
        line_count = 0
        for row in csv_reader:
            if line_count == 0:
                data['companies'] = len(row)
                data["Company"] = row
            else:
                data["Preference"].append(row)
                # if "Preference" in data.keys():
                #     data["Preference"].append(row)
                # else:
                #     data["Preference"] = row
            line_count += 1  
        data['students'] = line_count - 1

    return data          

def main():
    location = os.path.realpath(os.path.join(os.getcwd(), os.path.dirname(__file__)))
    postfix = 'test2'
    filename_read = os.path.join(location, 'data', "".join([postfix, '.csv']))
    filename_write = os.path.join(location, 'data', "".join([postfix, '.dzn']))
    data = read_csv(filename_read)
    with open(filename_write, 'w') as dzn_file:
        dzn_file.write("\n".join(dzn.dict2dzn(data)))


if __name__ == "__main__":
    main()