
import pandas as pd
import numpy as np
import pathlib as pl

# === setting paths ===
# load walker range file path, only one file
range_file_path = pl.Path(r"Z:\BioMotionAnlyze\analyze\data\GPDM\range_walker_point\range_walker_point.pkl")

# folder path settings(walker data and noisy walker data folder)
walker_data_dir = pl.Path(r"Z:\BioMotionAnlyze\analyze\data\GPDM\dynamic_data_pkl")
noisy_data_dir = pl.Path(r"Z:\BioMotionAnlyze\analyze\data\GPDM\noisy_walker")



# === setting walker files input mode ===
# read mode
mode = "folder"  # options: "single", "multi", "folder"

# single mode file
single_file = "trial_11_0.pkl"

# multi mode files
multi_files = ["files here"]



# === setting params and read data ===
# guassian noise level
noise_level = 0.05  

# foveal radius
foveal_radius = 1  # deg

# read walker range data
range_walker_point = pd.read_pickle(range_file_path)

# === label noisy points ====
def label_noisy_point(walker_data_file):
   # 1.check file path
   if not walker_data_file.exists():
      print(f"File {walker_data_file} does not exist.")
      exit()

   # 2.read walker data
   walker_data = pd.read_pickle(walker_data_file)

   # 3.read cols needed to process
   cols_needed = ['deg_x', 'deg_y']
   cols_walker = []
   for i in range(1,16):
       cols_needed.append(f'x{i}_deg')
       cols_needed.append(f'y{i}_deg')
       cols_walker.append(f'x{i}_deg')
       cols_walker.append(f'y{i}_deg')
   df = walker_data[cols_needed]
   df_walker = walker_data[cols_walker]

   # 4.label noise points
   # creat a matrix to store noise mask label
   mask_label = []
   # calculate distance from gaze point to each walker point
   rows = df.shape[0]
   for i in range(rows):
       deg_x = df.at[i, 'deg_x']
       deg_y = df.at[i, 'deg_y']
       temp_label = []
       for j in range(1,16):
           point_x = df.at[i, f'x{j}_deg']
           point_y = df.at[i, f'y{j}_deg']
           distance = np.sqrt((deg_x - point_x)**2 + (deg_y - point_y)**2)
           if distance <= foveal_radius:
               temp_label.append(0)  # 0 means clear point
           else:
               temp_label.append(1)  # 1 means noisy point
       mask_label.append(temp_label)

   # 5.convert to dataframe
   mask_df = pd.DataFrame(mask_label,
   columns=[f'point{j}_mask' for j in range(1, 16)])
   return mask_df, df_walker



# === according to mask label, add noise to noisy points ===
def add_noise(mask_df, df_walker, output_file):
    noise_std = {}
    for j in range(1, 16):
       noise_std[f'x{j}_deg'] = range_walker_point.loc[f'x{j}_deg'] * noise_level
       noise_std[f'y{j}_deg'] = range_walker_point.loc[f'y{j}_deg'] * noise_level

    for i in range(df_walker.shape[0]):
        for j in range(1,16):
            if mask_df.at[i, f'point{j}_mask'] == 1:
                # add noise
                df_walker.at[i, f'x{j}_deg'] += np.random.normal(0, noise_std[f'x{j}_deg'])
                df_walker.at[i, f'y{j}_deg'] += np.random.normal(0, noise_std[f'y{j}_deg'])
    
    # save noisy walker data
    df_walker.to_pickle(output_file)
    print(f"Noisy walker data saved to {output_file} successfully.")



# === main function ===
def main():


    # 1.check if output folder exists
    if walker_data_dir.is_dir():
        pass
    else:
        print(" walker data folder does not exist!")
        exit()

    if noisy_data_dir.is_dir():
        pass
    else:
        print("noisy data folder does not exist!")
        exit()
    
    # 2.info print
    print(f"mode: {mode}")
    print(f"input_path: {walker_data_dir}")
    print(f"output_path: {noisy_data_dir}")

    # 3.convert according to mode
    if mode == "single":
        input_file = walker_data_dir / single_file
        output_file = noisy_data_dir / (input_file.stem + '_noisy.pkl')
        # noise addition
        mask_df, df_walker = label_noisy_point(input_file)
        add_noise(mask_df, df_walker, output_file)

    elif mode == "multi":
        for file_name in multi_files:
            input_file = walker_data_dir / file_name
            output_file = noisy_data_dir / (input_file.stem + '_noisy.pkl')
            # noise addition
            mask_df, df_walker = label_noisy_point(input_file)
            add_noise(mask_df, df_walker, output_file)

    elif mode == "folder":
        # use lathlib glob to get all csv files in the folder
        all_walker_data_files = list(walker_data_dir.glob("*.pkl"))
        print(f"Found {len(all_walker_data_files)} walker data files.")

        for input_file in all_walker_data_files:
            output_file = noisy_data_dir / (input_file.stem + '_noisy.pkl')
            # noise addition
            mask_df, df_walker = label_noisy_point(input_file)
            add_noise(mask_df, df_walker, output_file)



if __name__ == "__main__":
    main()
    print("Noise addition process completed.")