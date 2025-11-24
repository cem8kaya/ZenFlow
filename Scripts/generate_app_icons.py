#!/usr/bin/env python3

"""
ZenFlow App Icon Generator
Generates all iOS app icon sizes with the Breathing Circles design
"""

import os
import json
from pathlib import Path
from PIL import Image, ImageDraw

# Icon Colors (from ZenTheme)
CALM_BLUE = (89, 115, 217)  # #5973D9
SERENE_PURPLE = (128, 89, 217)  # #8059D9
SOFT_PURPLE = (115, 89, 166)  # #7359A6
DEEP_INDIGO = (46, 38, 89)  # #2E2659
LIGHTER_INDIGO = (64, 56, 107)  # #40386B

# iOS Icon Sizes
ICON_SIZES = [
    # iPhone
    ("icon-20@2x.png", 40),
    ("icon-20@3x.png", 60),
    ("icon-29@2x.png", 58),
    ("icon-29@3x.png", 87),
    ("icon-40@2x.png", 80),
    ("icon-40@3x.png", 120),
    ("icon-60@2x.png", 120),
    ("icon-60@3x.png", 180),
    # iPad
    ("icon-20.png", 20),
    ("icon-20@2x-ipad.png", 40),
    ("icon-29.png", 29),
    ("icon-29@2x-ipad.png", 58),
    ("icon-40.png", 40),
    ("icon-40@2x-ipad.png", 80),
    ("icon-76.png", 76),
    ("icon-76@2x.png", 152),
    ("icon-83.5@2x.png", 167),
    # App Store
    ("icon-1024.png", 1024),
]

# Contents.json template
CONTENTS_JSON = {
    "images": [
        {"filename": "icon-20@2x.png", "idiom": "iphone", "scale": "2x", "size": "20x20"},
        {"filename": "icon-20@3x.png", "idiom": "iphone", "scale": "3x", "size": "20x20"},
        {"filename": "icon-29@2x.png", "idiom": "iphone", "scale": "2x", "size": "29x29"},
        {"filename": "icon-29@3x.png", "idiom": "iphone", "scale": "3x", "size": "29x29"},
        {"filename": "icon-40@2x.png", "idiom": "iphone", "scale": "2x", "size": "40x40"},
        {"filename": "icon-40@3x.png", "idiom": "iphone", "scale": "3x", "size": "40x40"},
        {"filename": "icon-60@2x.png", "idiom": "iphone", "scale": "2x", "size": "60x60"},
        {"filename": "icon-60@3x.png", "idiom": "iphone", "scale": "3x", "size": "60x60"},
        {"filename": "icon-20.png", "idiom": "ipad", "scale": "1x", "size": "20x20"},
        {"filename": "icon-20@2x-ipad.png", "idiom": "ipad", "scale": "2x", "size": "20x20"},
        {"filename": "icon-29.png", "idiom": "ipad", "scale": "1x", "size": "29x29"},
        {"filename": "icon-29@2x-ipad.png", "idiom": "ipad", "scale": "2x", "size": "29x29"},
        {"filename": "icon-40.png", "idiom": "ipad", "scale": "1x", "size": "40x40"},
        {"filename": "icon-40@2x-ipad.png", "idiom": "ipad", "scale": "2x", "size": "40x40"},
        {"filename": "icon-76.png", "idiom": "ipad", "scale": "1x", "size": "76x76"},
        {"filename": "icon-76@2x.png", "idiom": "ipad", "scale": "2x", "size": "76x76"},
        {"filename": "icon-83.5@2x.png", "idiom": "ipad", "scale": "2x", "size": "83.5x83.5"},
        {"filename": "icon-1024.png", "idiom": "ios-marketing", "scale": "1x", "size": "1024x1024"},
    ],
    "info": {"author": "xcode", "version": 1}
}


def create_radial_gradient(size, center, start_radius, end_radius, start_color, end_color):
    """Create a radial gradient"""
    img = Image.new('RGBA', (size, size), (0, 0, 0, 0))
    draw = ImageDraw.Draw(img)

    cx, cy = center
    steps = int(end_radius - start_radius)

    for i in range(steps):
        progress = i / steps
        radius = start_radius + (end_radius - start_radius) * progress

        # Interpolate colors
        r = int(start_color[0] + (end_color[0] - start_color[0]) * progress)
        g = int(start_color[1] + (end_color[1] - start_color[1]) * progress)
        b = int(start_color[2] + (end_color[2] - start_color[2]) * progress)
        a = int(start_color[3] + (end_color[3] - start_color[3]) * progress) if len(start_color) > 3 else 255

        bbox = [cx - radius, cy - radius, cx + radius, cy + radius]
        draw.ellipse(bbox, fill=(r, g, b, a))

    return img


def draw_breathing_circles_icon(size):
    """Draw the Breathing Circles icon design"""
    # Create image with background gradient
    img = Image.new('RGB', (size, size))
    draw = ImageDraw.Draw(img, 'RGBA')

    # Background gradient (top-left to bottom-right)
    for y in range(size):
        progress = y / size
        r = int(LIGHTER_INDIGO[0] + (DEEP_INDIGO[0] - LIGHTER_INDIGO[0]) * progress)
        g = int(LIGHTER_INDIGO[1] + (DEEP_INDIGO[1] - LIGHTER_INDIGO[1]) * progress)
        b = int(LIGHTER_INDIGO[2] + (DEEP_INDIGO[2] - LIGHTER_INDIGO[2]) * progress)
        draw.line([(0, y), (size, y)], fill=(r, g, b))

    # Calculate scale
    scale = size / 1024.0
    center = (size // 2, size // 2)

    # Outer glow
    glow_start = SERENE_PURPLE + (76,)  # ~30% opacity
    glow_end = (0, 0, 0, 0)
    glow = create_radial_gradient(
        size, center,
        int(100 * scale), int(300 * scale),
        glow_start, glow_end
    )
    img.paste(glow, (0, 0), glow)

    # Draw concentric circles
    circles = [
        (400 * scale, 3 * scale, SOFT_PURPLE + (102,)),   # 40% opacity
        (330 * scale, 4 * scale, SOFT_PURPLE + (128,)),   # 50% opacity
        (260 * scale, 5 * scale, CALM_BLUE + (153,)),     # 60% opacity
        (190 * scale, 6 * scale, CALM_BLUE + (179,)),     # 70% opacity
        (120 * scale, 7 * scale, CALM_BLUE + (204,)),     # 80% opacity
    ]

    draw_with_alpha = ImageDraw.Draw(img, 'RGBA')

    for radius, width, color in circles:
        bbox = [
            center[0] - radius, center[1] - radius,
            center[0] + radius, center[1] + radius
        ]
        # Draw circle as outline
        for i in range(int(width)):
            r = radius - i/2
            bbox_i = [
                center[0] - r, center[1] - r,
                center[0] + r, center[1] + r
            ]
            draw_with_alpha.ellipse(bbox_i, outline=color)

    # Center filled circle with radial gradient
    center_radius = int(40 * scale)

    # Inner gradient layers
    gradient_steps = [
        (5 * scale, (255, 255, 255, 230)),      # white center
        (25 * scale, CALM_BLUE + (204,)),       # calm blue middle
        (40 * scale, SERENE_PURPLE + (179,)),   # serene purple outer
    ]

    for i in range(len(gradient_steps) - 1):
        start_r, start_c = gradient_steps[i]
        end_r, end_c = gradient_steps[i + 1]

        gradient = create_radial_gradient(
            size, center,
            int(start_r), int(end_r),
            start_c, end_c
        )
        img.paste(gradient, (0, 0), gradient)

    # Center circle stroke
    stroke_width = max(1, int(2 * scale))
    for i in range(stroke_width):
        r = center_radius - i/2
        bbox = [
            center[0] - r, center[1] - r,
            center[0] + r, center[1] + r
        ]
        draw_with_alpha.ellipse(bbox, outline=CALM_BLUE + (255,))

    return img


def generate_all_icons(output_dir):
    """Generate all iOS icon sizes"""
    print("🎨 ZenFlow App Icon Generator")
    print("━" * 42)
    print("📱 Design: Breathing Circles")
    print(f"📍 Output: {output_dir}")
    print()

    # Create output directory
    output_path = Path(output_dir)
    output_path.mkdir(parents=True, exist_ok=True)

    success_count = 0
    fail_count = 0

    # Generate each icon size
    for filename, pixel_size in ICON_SIZES:
        try:
            icon = draw_breathing_circles_icon(pixel_size)
            icon.save(output_path / filename, 'PNG')
            print(f"✅ {filename:25} ({pixel_size}x{pixel_size}px)")
            success_count += 1
        except Exception as e:
            print(f"❌ Failed: {filename} - {e}")
            fail_count += 1

    # Write Contents.json
    try:
        with open(output_path / "Contents.json", 'w') as f:
            json.dump(CONTENTS_JSON, f, indent=2)
        print("✅ Contents.json")
    except Exception as e:
        print(f"❌ Failed to write Contents.json: {e}")
        fail_count += 1

    print()
    print("━" * 42)
    print("✨ Generation complete!")
    print(f"📊 Success: {success_count}/{len(ICON_SIZES)} icons")
    if fail_count > 0:
        print(f"⚠️  Failed: {fail_count}")
    print()
    print("🎯 Ready for Xcode build and App Store submission")


if __name__ == "__main__":
    # Determine output path
    script_dir = Path(__file__).parent
    project_dir = script_dir.parent
    output_dir = project_dir / "ZenFlow" / "Assets.xcassets" / "AppIcon.appiconset"

    generate_all_icons(output_dir)
