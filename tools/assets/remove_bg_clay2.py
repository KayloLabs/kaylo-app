from rembg import remove
from PIL import Image
import sys

def process(input_path, output_path):
    print(f"Processing {input_path}...")
    try:
        input_image = Image.open(input_path).convert('RGBA')
        output_image = remove(input_image)
        output_image.save(output_path, format='PNG')
        print(f"Saved {output_path}")
    except Exception as e:
        print(f"Failed to process {input_path}: {e}")

process('assets_kaylo/3d/hero_kerala_clay.png', 'assets_kaylo/3d_transparent/hero_kerala_clay.png')
process('assets_kaylo/3d/hero_workers_clay.png', 'assets_kaylo/3d_transparent/hero_workers_clay.png')
