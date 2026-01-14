import pandas as pd
import pathlib as pl

# config convert mode
mode = "folder"  # options: "single", "multi", "folder"

# folder path settings
csv_data_dir = pl.Path(r"Z:\BioMotionAnlyze\analyze\data\pymovement data\exp 202504\dynamic data")
pkl_data_dir = pl.Path(r"Z:\BioMotionAnlyze\analyze\data\GPDM\dynamic_data_pkl")

# single mode file
single_file = "trial_11_0.csv"

# multi mode files
multi_files = ["files here"]



# convert walking data from csv to pkl
def  convert_csv_to_pkl(csv_file_path, pkl_data_dir):
    
    # 1.check if csv file exists
    if not csv_file_path.exists():
        print(f"CSV file {csv_file_path} does not exist.")
        return
    
    # 2.csv exists, read csv file use pandas
    df = pd.read_csv(csv_file_path)

    # 3.create file path to save pkl
    pkl_file_path = pkl_data_dir / (csv_file_path.stem + '.pkl')

    # 4.convert and save
    df.to_pickle(pkl_file_path)
    print(f"Converted {csv_file_path.stem + '.csv'} to {pkl_file_path.stem + '.pkl'} successfully.")



# main function
def main():
    # 1.check if output folder exists
    if csv_data_dir.is_dir():
        # in python if statement, pass means do nothing
        pass
    else:
        print("folder does not exist!")

    # 2.info print
    print(f"mode: {mode}")
    print(f"input_path: {csv_data_dir}")
    print(f"output_path: {pkl_data_dir}")

    # 3.convert according to mode
    if mode == "single":
        target_file = csv_data_dir / single_file
        # convert file
        convert_csv_to_pkl(target_file, pkl_data_dir)

    elif mode == "multi":
        for file_name in multi_files:
            target_file = csv_data_dir / file_name
            output_file = pkl_data_dir / (file_name.replace('.csv', '.pkl'))
            convert_csv_to_pkl(target_file, pkl_data_dir)

    elif mode == "folder":
        # use lathlib glob to get all csv files in the folder
        all_csv_files = list(csv_data_dir.glob("*.csv"))
        print(f"Found {len(all_csv_files)} csv files.")

        # convert each file
        for target_file in all_csv_files:
            convert_csv_to_pkl(target_file, pkl_data_dir)


if __name__ == "__main__":
    main()

    """ 
    # debug use only
    # check output pkl file
    data = pd.read_pickle("Z:/BioMotionAnlyze/analyze/GPDM/test/trial_11_0.pkl")
    print(data)
    """