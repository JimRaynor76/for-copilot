# === blink calculation ===
def find_blinks(hardware_params, eye_data_df):
    """
    This funtion finds blinks in eye data based on velocity threshold.
    Due to eyelink data has a strange voltage change during blink, when a blink
    occurs, the voltage change will be very large, almost close to 10thousands, and 
    suddenly turn to zoro, keep for a short time, then return to 10thousands again,
    after this return to normal voltage range. So we can use this feature to detect blinks.
    Fist, we find blinks based on this voltage change feature, then we calculate blinks based
    on velocity threshold way refered in a paper.
    """
    # blinks params setting
    vd = hardware_params["viewing_distance_cm"] # viewing distance in cm
    sr = hardware_params["sampling_rate_hz"] # sampling rate in Hz
    si = 1 / sr # sampling interval in s
    vt_deg = 80 # velocity threshold in degree/s
    vt_del = 30 # velocity threshold to delete blink parts in degree/s
    vt_blink_voltage = 1000 # use a very large vlocity threshold to find blinks based on voltage change feature
    vThresh = vd * np.deg2rad(vt_deg) # velocity threshold in cm/s
    vThresh_del = vd * np.deg2rad(vt_del) # velocity threshold to delet blink parts in cm/s
    vThresh_blink_voltage = vd * np.deg2rad(vt_blink_voltage)

    # create a list to store blink info
    blink_list = []

    # prepare for velocity calculation
    pos_x = eye_data_df["lx_cm"].to_numpy()
    pos_y = eye_data_df["ly_cm"].to_numpy()
    vel_x = np.diff(pos_x) / si
    vel_y = np.diff(pos_y) / si
    vel = np.sqrt(vel_x**2 + vel_y**2)

    # 