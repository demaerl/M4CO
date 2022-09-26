import pandas as pd
import sys
from pymzn import dzn

def read_company(filename):
    data = pd.read_csv(filename)
    columns = list(data.columns)
    
    output = {}
    for col in data.columns:
        output[col] = []
        
    for i in range(len(columns)):
        output[columns[i]] = list(data.iloc[:, i])

    output_name = filename.split('.')[0] + ".dzn"
    with open(output_name, 'w') as dzn_file:
        dzn_file.write("\n".join(dzn.dict2dzn(output))) 
    
        
if __name__ == "__main__":
    read_company(sys.argv[1])
    
    



