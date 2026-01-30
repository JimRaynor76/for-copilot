import pymovements as pm

def load_dataset(dataset_path:str, **load_kwargs):
    experiment = pm.gaze.Experiment(
        screen_width_px=1920,
        screen_height_px=1080,
        screen_width_cm=72.0,
        screen_height_cm=40.5,
        distance_cm=57.0,
        origin='upper left',
        sampling_rate=1000,
    )

    # any type in subject_id
    filename_format = {'gaze': r'trial_{subject_id}_{trial_id:d}.csv'}

    
    filename_format_schema_overrides = {'gaze': {
        'subject_id': str,
        'trial_id': int,
        }
    }


    custom_read_kwargs = {
        'gaze': {'separator': ','},
    }

    trial_columns = ['text_id', 'page_id']

    time_column = 'timestamp'
    time_unit = 'ms'
    pixel_columns = ['x', 'y']

    dataset_definition = pm.DatasetDefinition(
        name='my_dataset',
        has_files={'gaze': True, 'precomputed_events': False, 'precomputed_reading_measures': False},
        experiment=experiment,
        filename_format=filename_format,
        filename_format_schema_overrides=filename_format_schema_overrides,
        custom_read_kwargs=custom_read_kwargs,
        time_column=time_column,
        time_unit=time_unit,
        pixel_columns=pixel_columns,
    )

    dataset = pm.Dataset(
        definition=dataset_definition,
        path=dataset_path,
    )

    dataset.load(**load_kwargs)
    
    return dataset