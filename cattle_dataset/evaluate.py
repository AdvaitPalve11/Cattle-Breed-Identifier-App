import tensorflow as tf
from keras.models import load_model

if hasattr(tf, 'keras'):
    models = tf.keras.models
else:
    import keras
    models = keras.models
import numpy as np
from sklearn.metrics import classification_report, confusion_matrix, roc_curve, auc, precision_recall_fscore_support
import matplotlib.pyplot as plt
import seaborn as sns
import pandas as pd
import os
from itertools import cycle

# Set style for better visualizations
plt.style.use('default')
sns.set_palette("deep")

# Try multiple possible model paths
model_paths = ['cattle_breed_model.h5', 'best_model.h5']
model = None

for model_path in model_paths:
    if os.path.exists(model_path):
        try:
            model = load_model(model_path)
            print(f"Successfully loaded model from {model_path}")
            break
        except Exception as e:
            print(f"Error loading model from {model_path}: {e}")
            continue

if model is None:
    raise FileNotFoundError("Could not find a valid model file. Tried: cattle_breed_model.h5, best_model.h5")

# Try multiple possible class names paths
class_names_paths = ['class_names.npy', 'class_mapping.npy']
class_names = None

for class_path in class_names_paths:
    if os.path.exists(class_path):
        try:
            class_names = np.load(class_path, allow_pickle=True)
            print(f"Successfully loaded class names from {class_path}")
            break
        except Exception as e:
            print(f"Error loading class names from {class_path}: {e}")
            continue

if class_names is None:
    raise FileNotFoundError("Could not find class names file. Tried: class_names.npy, class_mapping.npy")

# Fix: Handle different formats of class_names
if isinstance(class_names, np.ndarray):
    if class_names.size == 1:
        # If it's an array with a single item, extract it
        class_names = class_names.item()
    else:
        # If it's an array with multiple items, convert to list
        class_names = class_names.tolist()

# If class_names is a dictionary, extract the class names
if isinstance(class_names, dict):
    class_names = list(class_names.values())
elif isinstance(class_names, list):
    # Already a list, no conversion needed
    pass
else:
    # Handle other cases (e.g., if it's a single string)
    class_names = [class_names]

print(f"Class names: {class_names}")

# Try multiple possible test directory paths
test_dirs = ['test', 'cattle_dataset/test', '../test']
test_gen = None

# Create test data generator with the same preprocessing as training
preprocess = tf.keras.applications.mobilenet_v2.preprocess_input
test_datagen = tf.keras.preprocessing.image.ImageDataGenerator(preprocessing_function=preprocess)

for test_dir in test_dirs:
    if os.path.exists(test_dir):
        try:
            test_gen = test_datagen.flow_from_directory(
                test_dir,
                target_size=(224, 224),
                batch_size=32,
                class_mode='categorical',
                shuffle=False  # Important for maintaining order
            )
            print(f"Using test directory: {test_dir}")
            break
        except Exception as e:
            print(f"Error with test directory {test_dir}: {e}")
            continue

if test_gen is None:
    raise FileNotFoundError("Could not find test directory. Tried: test, cattle_dataset/test, ../test")

# Get predictions
print("Generating predictions...")
preds = model.predict(test_gen, verbose=1)
y_pred = np.argmax(preds, axis=1)
y_true = test_gen.classes
y_prob = preds  # Probability scores for each class

# Classification report
print("\n" + "="*50)
print("CLASSIFICATION REPORT")
print("="*50)
report = classification_report(y_true, y_pred, target_names=class_names, output_dict=True)
print(classification_report(y_true, y_pred, target_names=class_names))

# Convert to DataFrame for better visualization
report_df = pd.DataFrame(report).transpose()
report_df.to_csv('classification_report.csv')
print("\nDetailed classification report saved to 'classification_report.csv'")

# Confusion matrix
cm = confusion_matrix(y_true, y_pred)

# Plot confusion matrix
plt.figure(figsize=(max(10, len(class_names)*0.8), max(8, len(class_names)*0.6)))
sns.heatmap(cm, annot=True, fmt='d', cmap='Blues', 
            xticklabels=class_names, yticklabels=class_names)
plt.title('Confusion Matrix', fontsize=16)
plt.xlabel('Predicted Label', fontsize=14)
plt.ylabel('True Label', fontsize=14)
plt.xticks(rotation=45, ha='right')
plt.yticks(rotation=0)
plt.tight_layout()
plt.savefig('confusion_matrix.png', dpi=300, bbox_inches='tight')
plt.show()
print('Confusion matrix saved as confusion_matrix.png')

# Normalized confusion matrix
cm_normalized = cm.astype('float') / cm.sum(axis=1)[:, np.newaxis]
cm_normalized = np.nan_to_num(cm_normalized)  # Handle division by zero

plt.figure(figsize=(max(10, len(class_names)*0.8), max(8, len(class_names)*0.6)))
sns.heatmap(cm_normalized, annot=True, fmt='.2f', cmap='Blues',
            xticklabels=class_names, yticklabels=class_names)
plt.title('Normalized Confusion Matrix', fontsize=16)
plt.xlabel('Predicted Label', fontsize=14)
plt.ylabel('True Label', fontsize=14)
plt.xticks(rotation=45, ha='right')
plt.yticks(rotation=0)
plt.tight_layout()
plt.savefig('confusion_matrix_normalized.png', dpi=300, bbox_inches='tight')
plt.show()
print('Normalized confusion matrix saved as confusion_matrix_normalized.png')

# ROC Curve for multi-class (if not too many classes)
if len(class_names) <= 15:  # Increased limit to 15 classes
    fpr = dict()
    tpr = dict()
    roc_auc = dict()
    
    # Compute ROC curve and ROC area for each class
    for i in range(len(class_names)):
        try:
            fpr[i], tpr[i], _ = roc_curve((y_true == i).astype(int), y_prob[:, i])
            roc_auc[i] = auc(fpr[i], tpr[i])
        except Exception as e:
            print(f"Error generating ROC curve for class {class_names[i]}: {e}")
            continue
    
    # Plot all ROC curves if we have at least one valid curve
    if fpr and tpr:
        plt.figure(figsize=(10, 8))
        colors = cycle(['aqua', 'darkorange', 'cornflowerblue', 'green', 'red', 
                       'purple', 'brown', 'pink', 'gray', 'olive', 'cyan', 'magenta', 
                       'yellow', 'black', 'white'])
        
        for i, color in zip(range(len(class_names)), colors):
            if i in fpr and i in tpr:  # Only plot if we have data for this class
                plt.plot(fpr[i], tpr[i], color=color, lw=2,
                         label='ROC curve of class {0} (area = {1:0.2f})'
                         ''.format(class_names[i], roc_auc[i]))
        
        plt.plot([0, 1], [0, 1], 'k--', lw=2)
        plt.xlim([0.0, 1.0])
        plt.ylim([0.0, 1.05])
        plt.xlabel('False Positive Rate')
        plt.ylabel('True Positive Rate')
        plt.title('Receiver Operating Characteristic (ROC) Curves')
        plt.legend(loc="lower right")
        plt.tight_layout()
        plt.savefig('roc_curves.png', dpi=300, bbox_inches='tight')
        plt.show()
        print('ROC curves saved as roc_curves.png')
    else:
        print("Skipping ROC curves: No valid ROC data generated")

# Precision-Recall metrics
precision, recall, f1, support = precision_recall_fscore_support(y_true, y_pred)

# Class-wise accuracy
class_accuracy = {}
for i in range(len(class_names)):
    class_mask = y_true == i
    if np.sum(class_mask) > 0:
        class_accuracy[class_names[i]] = np.sum(y_pred[class_mask] == i) / np.sum(class_mask)
    else:
        class_accuracy[class_names[i]] = 0  # Handle case with no samples for this class

# Create a bar plot of class-wise accuracy
plt.figure(figsize=(max(12, len(class_names)*0.5), 6))
plt.bar(range(len(class_accuracy)), list(class_accuracy.values()), align='center')
plt.xticks(range(len(class_accuracy)), list(class_accuracy.keys()), rotation=45, ha='right')
plt.xlabel('Class')
plt.ylabel('Accuracy')
plt.title('Class-wise Accuracy')
plt.tight_layout()
plt.savefig('class_accuracy.png', dpi=300, bbox_inches='tight')
plt.show()
print('Class-wise accuracy plot saved as class_accuracy.png')

# Save misclassified examples information
misclassified_idx = np.where(y_pred != y_true)[0]
misclassified_examples = []

for idx in misclassified_idx:
    misclassified_examples.append({
        'true_class': class_names[y_true[idx]],
        'predicted_class': class_names[y_pred[idx]],
        'confidence': np.max(y_prob[idx]),
        'file_path': test_gen.filepaths[idx]
    })

misclassified_df = pd.DataFrame(misclassified_examples)
if not misclassified_df.empty:
    misclassified_df.to_csv('misclassified_examples.csv', index=False)
    print(f"Misclassified examples saved to 'misclassified_examples.csv' ({len(misclassified_idx)} examples)")
    
    # Display top misclassifications
    print("\nTop 10 misclassifications by confidence:")
    top_misclassified = misclassified_df.nlargest(min(10, len(misclassified_df)), 'confidence')
    print(top_misclassified[['true_class', 'predicted_class', 'confidence']].to_string(index=False))
else:
    print("No misclassified examples found!")

# Create comprehensive metrics dataframe
metrics_data = []
for i, class_name in enumerate(class_names):
    metrics_data.append({
        'Class': class_name,
        'Precision': precision[i] if i < len(precision) else 0,
        'Recall': recall[i] if i < len(recall) else 0,
        'F1-Score': f1[i] if i < len(f1) else 0,
        'Support': support[i] if i < len(support) else 0,
        'Accuracy': class_accuracy[class_name]
    })

metrics_df = pd.DataFrame(metrics_data)
metrics_df.to_csv('detailed_metrics.csv', index=False)
print("\nDetailed metrics saved to 'detailed_metrics.csv'")

# Overall accuracy
accuracy = np.sum(y_pred == y_true) / len(y_true)
print(f"\nOverall Accuracy: {accuracy:.4f} ({accuracy*100:.2f}%)")

# Calculate and display per-class metrics
print("\n" + "="*50)
print("PER-CLASS METRICS")
print("="*50)
for i, class_name in enumerate(class_names):
    class_mask = y_true == i
    if np.sum(class_mask) > 0:
        class_acc = np.sum(y_pred[class_mask] == i) / np.sum(class_mask)
        print(f"{class_name}: {class_acc:.4f} ({class_acc*100:.2f}%)")
    else:
        print(f"{class_name}: No samples in test set")

print("\nEvaluation completed! All plots and reports saved.")