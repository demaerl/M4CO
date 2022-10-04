import shutil


template = "e_{f}_{r}_{s}.dzn"
rhos = range(0, 10001, 2000)
sigmas = range(0, 101, 20)
dzn_files = ["005_003_01.dzn", "009_006_03.dzn", "020_016_02.dzn",
             "023_017_03.dzn", "047_015_16.dzn", "162_146_08.dzn"]


# Copies filename to filename_rho_sigma_e, and adds the rho and sigma parameters to the copy
def create_rho_sigma_file(filename, rho, sigma):
    copy_name = template.format(f=filename[:-4], r=rho, s=sigma)
    shutil.copyfile(filename, copy_name)
    f = open(copy_name, "a")
    f.write("\nrho = " + str(rho) + ";")
    f.write("\nsigma = " + str(sigma) + ";\n")
    f.close()
        
if __name__ == "__main__":
    for r in rhos:
        for s in sigmas:
            for i, f in enumerate(dzn_files):
                create_rho_sigma_file(f, r, s)

    
    

