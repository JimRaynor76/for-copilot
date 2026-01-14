# This script analyzes the frequency of walker display and gait,
# calculating SD of every points x,y coordinates in degree unit.
# Auther: F, Date: 2026.1.1

import pandas as pd
import numpy as np
import pathlib as pl
from scipy.signal import find_peaks

# intialize parameters
sr = 1000  # sampling rate in Hz
si = 1000/sr  # sampling interval in ms
change_timnes = 5 # how many times the walker changes direction, must > 3
pick_ci = 2 # which change interval to pick for frequency calculation

# load walker frame file path,
# load walker point data out put path
file_path = pl.Path(r"Z:/BioMotionAnlyze/analyze/GPDM/test/trial_11_0.pkl")
range_output_path = pl.Path(r"Z:/BioMotionAnlyze/analyze/GPDM/test/range_walker_point.pkl")

#  read pickle file
if not file_path.exists():
    print(f"File {file_path.name} does not exist.")
    exit()
df = pd.read_pickle(file_path)

# display dataFrame and pick one column
# print(df.columns)
sample_col = df['x1_deg'].values


# claclulate walker display frequency
diff = np.diff(sample_col)
change_indices = np.where(diff != 0)[0] + 1 # +1 because py index from 0 not 1
change_indices = change_indices[:change_timnes] # limit to specified number of changes

if len(change_indices) >= change_timnes:    
    walker_fct = np.diff(change_indices) # frames changes time
    walker_frame = walker_fct[pick_ci] * si # pick up any frame interval as time/frame, unit: ms/frame
    walker_frequency = 1000 / walker_frame

    # out put ms/frame and frequency
    print("walker frame interval: {:.2f} ms/frame".format(walker_frame))
    print("walker frame frequency: {:.2f} Hz".format(walker_frequency))

else:
    print("Not enough direction changes detected in the data.")


# claculate gait frequency
peaks, _ = find_peaks(sample_col)
# print( "Detected peaks at indices:", peaks) # cheack peaks

if len(peaks) < 2:
    print("Not enough peaks detected for gait frequency calculation.")
    exit()

else:
    gait_cycle = peaks[1] - peaks[0]  # times per gait cycle
    gait_frequency = 1000 / gait_cycle  # frequency in Hz

    # out put gait cycle and frequency
    print("gait cycle: {} ms".format(gait_cycle))
    print("gait frequency: {:.2f} Hz".format(gait_frequency))


# calculate range of x,y coordinates for each point
max_values = df.max()
min_values = df.min()
range_values = max_values - min_values

range_walker_point = pd.DataFrame({
    'range': range_values})

# output range data to pickle file
range_walker_point.to_pickle(range_output_path)
print("range of walker data output successfully to {}".format(range_output_path))