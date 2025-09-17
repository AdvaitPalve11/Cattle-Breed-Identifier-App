# Model Conversion Instructions

## Converting H5 to TFLite

1. Install requirements:
```bash
pip install tensorflow
```

2. Convert model:
```bash
python convert_model.py
```

This will:
- Load your .h5 model
- Convert it to TFLite format
- Save as `assets/model/cattle_breed_model.tflite`
- Print model input/output details

## Model Details

Original models:
- `best_model.h5`
- `cattle_breed_model.h5`

Converted model:
- `cattle_breed_model.tflite` (will be created by script)

Labels file:
- `labels.txt` - Contains breed names, one per line

## Integration Notes

The Flutter app expects:
1. Model file at: `assets/model/cattle_breed_model.tflite`
2. Labels file at: `assets/model/labels.txt`
3. Model input shape: [1, 224, 224, 3] (standard image input)
4. Model output: Array of class probabilities

## After Conversion

After running the conversion script, verify:
1. `cattle_breed_model.tflite` exists in assets/model/
2. File size is reasonable (typically a few MB)
3. The model info printed matches your expectations