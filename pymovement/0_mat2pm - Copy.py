'''
Turn original .mat file into pymovements compatible .csv files.

Each .csv is a single trial.

Header definition:
timestamp  x  y  stimulus_index subject  choice  is_correct
'''

import os
import numpy as np
import pandas as pd
from scipy.io import loadmat

def convert_one(file_path, output_dir):

    SCREEN_WIDTH_PX  = 1920
    SCREEN_HEIGHT_PX = 1080
    SCREEN_WIDTH_CM  = 72.0
    SCREEN_HEIGHT_CM = 40.5

    PX_PER_CM_X = SCREEN_WIDTH_PX  / SCREEN_WIDTH_CM
    PX_PER_CM_Y = SCREEN_HEIGHT_PX / SCREEN_HEIGHT_CM
    
    print(f"Processing {os.path.split(file_path)[-1]}")
    mdata = loadmat(file_path, squeeze_me=True, struct_as_record=False)
    root_key = next(k for k in mdata if not k.startswith("__"))    # there will be only one key like "file009"
    content = mdata[root_key]
    raw_list = content.trialsData.eyeData_cm.nonBlinksData
    stimulus_index_list = content.trlInfo[1]
    choice_list = content.choice
    
    subject_id = content.trialsParams[0].testSubjectInfo
    subject_num = int(subject_id[1:])
    if subject_id.startswith('M'):
        subject_num += 100
    elif subject_id.startswith('F'):
        subject_num = subject_num
    else:
        raise(NameError("Subject id should start with 'M' or 'F'"))

    for idx, (trial_raw, sti_ind, choice) in enumerate(zip(raw_list, stimulus_index_list, choice_list)):

        df = pd.DataFrame({
            "timestamp": np.arange(trial_raw.shape[0], dtype=int),
            "x": trial_raw[:, 0] * PX_PER_CM_X + SCREEN_WIDTH_PX // 2,
            "y": trial_raw[:, 1] * PX_PER_CM_Y + SCREEN_HEIGHT_PX // 2,
            "stimulus_index": sti_ind,
            "choice": int(choice),
            "subject_id": int(subject_num),
            "trial_id": int(idx),
        })

        output_file_path = os.path.join(output_dir, f"trial_{subject_num}_{idx}.csv")
        df.to_csv(output_file_path, index=False)

if __name__ == '__main__':
    input_dir = r"Z:\\BioMotionAnlyze\analyze\data\meta data\exp 202407\raw\exp 202407\fe\loadLvtRslt\trls"
    output_dir = r"Z:\\BioMotionAnlyze\analyze\data\pymovement data\exp 202407\fe\raw"
    print(os.listdir(input_dir))
    for file in os.listdir(input_dir):
        if file.endswith(".mat"):
            print(f"Processing {file}")
            file_path = os.path.join(input_dir, file)
            convert_one(file_path, output_dir)
    # convert_one(r"E:\BioMotion\data\processed0429\loadLvtRslt\trls\2025-04-28(122)-r0009-eyeTrcAnlyz.mat", output_dir)