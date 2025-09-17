import tensorflow as tf

# Load the .h5 model
model = tf.keras.models.load_model('assets/model/best_model.h5')  # or use cattle_breed_model.h5

# Convert to TFLite format
converter = tf.lite.TFLiteConverter.from_keras_model(model)
# Configure the converter for better compatibility
converter.target_spec.supported_ops = [
    tf.lite.OpsSet.TFLITE_BUILTINS,  # Enable standard TFLite ops
    tf.lite.OpsSet.SELECT_TF_OPS  # Enable TF ops if needed
]
converter.optimizations = [tf.lite.Optimize.DEFAULT]  # Enable default optimizations

# Convert the model
tflite_model = converter.convert()

# Save the TFLite model
with open('assets/model/cattle_breed_model.tflite', 'wb') as f:
    f.write(tflite_model)

print("Model converted successfully!")

# Optional: Print model details
interpreter = tf.lite.Interpreter(model_path='assets/model/cattle_breed_model.tflite')
interpreter.allocate_tensors()

# Get input and output details
input_details = interpreter.get_input_details()
output_details = interpreter.get_output_details()

print("\nModel Details:")
print("Input:", input_details)
print("Output:", output_details)