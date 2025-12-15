#!/usr/bin/env python3
"""
Generate app icons with proper padding for Flutter app
Usage: python generate_icons.py
"""

from PIL import Image, ImageDraw
import os

def create_icon_with_padding(input_path, output_path, size, padding_percent=15):
    """
    Create an icon with padding around the logo
    
    Args:
        input_path: Path to the source logo image
        output_path: Path to save the generated icon
        size: Size of the output icon (width and height)
        padding_percent: Percentage of padding (default 15%)
    """
    # Open the source image
    logo = Image.open(input_path)
    
    # Convert to RGBA if not already
    if logo.mode != 'RGBA':
        logo = logo.convert('RGBA')
    
    # Calculate the logo size with padding
    padding = int(size * padding_percent / 100)
    logo_size = size - (2 * padding)
    
    # Resize logo to fit
    logo = logo.resize((logo_size, logo_size), Image.Resampling.LANCZOS)
    
    # Create a new image with white background
    icon = Image.new('RGBA', (size, size), (255, 255, 255, 255))
    
    # Paste the logo centered with padding
    icon.paste(logo, (padding, padding), logo)
    
    # Convert to RGB for PNG
    icon = icon.convert('RGB')
    
    # Save the icon
    icon.save(output_path, 'PNG', quality=100)
    print(f"✓ Created {output_path} ({size}x{size}px)")

def main():
    # Define icon sizes for Android
    android_sizes = {
        'mipmap-mdpi': 48,
        'mipmap-hdpi': 72,
        'mipmap-xhdpi': 96,
        'mipmap-xxhdpi': 144,
        'mipmap-xxxhdpi': 192,
    }
    
    # iOS icon sizes
    ios_sizes = {
        'Icon-20@2x.png': 40,
        'Icon-20@3x.png': 60,
        'Icon-29@2x.png': 58,
        'Icon-29@3x.png': 87,
        'Icon-40@2x.png': 80,
        'Icon-40@3x.png': 120,
        'Icon-60@2x.png': 120,
        'Icon-60@3x.png': 180,
        'Icon-76.png': 76,
        'Icon-76@2x.png': 152,
        'Icon-83.5@2x.png': 167,
        'Icon-1024.png': 1024,
    }
    
    # Base paths
    base_dir = os.path.dirname(os.path.abspath(__file__))
    logo_path = os.path.join(base_dir, 'assets', 'images', 'Logo ITK.png')
    android_res_dir = os.path.join(base_dir, 'android', 'app', 'src', 'main', 'res')
    ios_assets_dir = os.path.join(base_dir, 'ios', 'Runner', 'Assets.xcassets', 'AppIcon.appiconset')
    
    if not os.path.exists(logo_path):
        print(f"❌ Logo not found: {logo_path}")
        return
    
    print(f"📱 Generating app icons from: {logo_path}\n")
    
    # Generate Android icons
    print("🤖 Android Icons:")
    for folder, size in android_sizes.items():
        output_dir = os.path.join(android_res_dir, folder)
        os.makedirs(output_dir, exist_ok=True)
        output_path = os.path.join(output_dir, 'ic_launcher.png')
        create_icon_with_padding(logo_path, output_path, size, padding_percent=15)
    
    print("\n🍎 iOS Icons:")
    os.makedirs(ios_assets_dir, exist_ok=True)
    for filename, size in ios_sizes.items():
        output_path = os.path.join(ios_assets_dir, filename)
        create_icon_with_padding(logo_path, output_path, size, padding_percent=15)
    
    # Create iOS Contents.json
    contents_json = {
        "images": [
            {"size": "20x20", "idiom": "iphone", "filename": "Icon-20@2x.png", "scale": "2x"},
            {"size": "20x20", "idiom": "iphone", "filename": "Icon-20@3x.png", "scale": "3x"},
            {"size": "29x29", "idiom": "iphone", "filename": "Icon-29@2x.png", "scale": "2x"},
            {"size": "29x29", "idiom": "iphone", "filename": "Icon-29@3x.png", "scale": "3x"},
            {"size": "40x40", "idiom": "iphone", "filename": "Icon-40@2x.png", "scale": "2x"},
            {"size": "40x40", "idiom": "iphone", "filename": "Icon-40@3x.png", "scale": "3x"},
            {"size": "60x60", "idiom": "iphone", "filename": "Icon-60@2x.png", "scale": "2x"},
            {"size": "60x60", "idiom": "iphone", "filename": "Icon-60@3x.png", "scale": "3x"},
            {"size": "20x20", "idiom": "ipad", "filename": "Icon-20@2x.png", "scale": "2x"},
            {"size": "29x29", "idiom": "ipad", "filename": "Icon-29@2x.png", "scale": "2x"},
            {"size": "40x40", "idiom": "ipad", "filename": "Icon-40@2x.png", "scale": "2x"},
            {"size": "76x76", "idiom": "ipad", "filename": "Icon-76.png", "scale": "1x"},
            {"size": "76x76", "idiom": "ipad", "filename": "Icon-76@2x.png", "scale": "2x"},
            {"size": "83.5x83.5", "idiom": "ipad", "filename": "Icon-83.5@2x.png", "scale": "2x"},
            {"size": "1024x1024", "idiom": "ios-marketing", "filename": "Icon-1024.png", "scale": "1x"}
        ],
        "info": {"version": 1, "author": "xcode"}
    }
    
    import json
    contents_path = os.path.join(ios_assets_dir, 'Contents.json')
    with open(contents_path, 'w') as f:
        json.dump(contents_json, f, indent=2)
    print(f"✓ Created {contents_path}")
    
    print("\n✅ All icons generated successfully!")
    print("\n📝 Next steps:")
    print("1. Run: flutter clean")
    print("2. Run: flutter pub get")
    print("3. Rebuild your app: flutter run")

if __name__ == '__main__':
    main()
