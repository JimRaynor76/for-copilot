import numpy as np
import polars as pl
import pymovements as pm
from matplotlib import pyplot as plt

from datasetDef import load_dataset

dataset: pm.dataset.dataset.Dataset = load_dataset(r"Z:\BioMotionAnlyze\analyze\data\pymovement data\202511_typeA\rt", preprocessed=True)

# detect events
dataset.detect_events('microsaccades', minimum_duration=12, threshold_factor=6)
dataset.detect_events('ivt', minimum_duration=100, velocity_threshold=20)

# compute event properties
dataset.compute_event_properties(["amplitude", "dispersion", "location", "peak_velocity", "disposition"])

dataset.save_events()
print(dataset.gaze[0])