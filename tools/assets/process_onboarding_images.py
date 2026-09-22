from rembg import remove
from PIL import Image
import os

def process(input_path):
    print(f"Processing {input_path}...")
    try:
        input_image = Image.open(input_path).convert('RGBA')
        output_image = remove(input_image)
        output_image.save(input_path, format='PNG')
        print(f"Saved {input_path}")
    except Exception as e:
        print(f"Failed to process {input_path}: {e}")

images = [
    'assets_kaylo/onboarding/onboarding_home.png',
    'assets_kaylo/onboarding/onboarding_farm.png',
    'assets_kaylo/onboarding/onboarding_care.png'
]

for img in images:
    if os.path.exists(img):
        process(img)
