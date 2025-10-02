import os
import warnings
warnings.filterwarnings('ignore')  # Suppress deprecation warnings

import tensorflow as tf
import tensorflowjs as tfjs
from tensorflow.keras.models import load_model

def convert_model():
    try:
        model_path = 'cattle_breed_model.h5'
        output_dir = 'tfjs_model'

        # Verify model exists
        if not os.path.exists(model_path):
            raise FileNotFoundError(f"Model file '{model_path}' not found")

        # Load model with custom objects if needed
        print("Loading model...")
        model = load_model(model_path, compile=False)

        # Ensure output directory exists
        os.makedirs(output_dir, exist_ok=True)

        # Convert model
        print("Converting model to TensorFlow.js format...")
        tfjs.converters.save_keras_model(model, output_dir)

        print(f"Model converted successfully!")
        print(f"Output saved in '{output_dir}' directory")

    except Exception as e:
        print(f"Error converting model: {str(e)}")
        raise

if __name__ == "__main__":
    convert_model()