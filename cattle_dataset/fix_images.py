import os
from PIL import Image

dirs = ["train", "validation"]  # add "test" if needed

for dataset_dir in dirs:
    for root, _, files in os.walk(dataset_dir):
        for file in files:
            if file.lower().endswith((".jpg", ".jpeg", ".png")):
                path = os.path.join(root, file)
                try:
                    img = Image.open(path)
                    if img.mode != 'RGB':
                        img = img.convert('RGB')
                        img.save(path)
                        print(f"Converted to RGB: {path}")
                except Exception as e:
                    print(f"Skipped corrupted image: {path}")

