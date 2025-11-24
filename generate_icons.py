#!/usr/bin/env python3
"""
Generate ZenFlow app icons in all required sizes.
Creates a zen-themed icon with concentric circles and gradient colors.
Copyright-free geometric design.
"""

from PIL import Image, ImageDraw
import os
import math

# Icon sizes needed (size, scale, filename)
ICON_SPECS = [
    # iPhone
    (20, 2, "icon-20@2x.png"),
    (20, 3, "icon-20@3x.png"),
    (29, 2, "icon-29@2x.png"),
    (29, 3, "icon-29@3x.png"),
    (40, 2, "icon-40@2x.png"),
    (40, 3, "icon-40@3x.png"),
    (60, 2, "icon-60@2x.png"),
    (60, 3, "icon-60@3x.png"),
    # iPad
    (20, 1, "icon-20.png"),
    (20, 2, "icon-20@2x-ipad.png"),
    (29, 1, "icon-29.png"),
    (29, 2, "icon-29@2x-ipad.png"),
    (40, 1, "icon-40.png"),
    (40, 2, "icon-40@2x-ipad.png"),
    (76, 1, "icon-76.png"),
    (76, 2, "icon-76@2x.png"),
    (83.5, 2, "icon-83.5@2x.png"),
    # App Store
    (1024, 1, "icon-1024.png"),
]

def create_zen_icon(size):
    """
    Create a zen-themed icon with concentric circles.

    Design concept:
    - Soft gradient background (blue to purple - calming colors)
    - Concentric circles representing ripples/breathing waves
    - Clean, minimal, meditative aesthetic
    """
    # Create image with gradient background
    img = Image.new('RGB', (size, size))
    draw = ImageDraw.Draw(img)

    # Create radial gradient background
    center_x, center_y = size // 2, size // 2
    max_radius = math.sqrt(center_x**2 + center_y**2)

    for y in range(size):
        for x in range(size):
            # Calculate distance from center
            distance = math.sqrt((x - center_x)**2 + (y - center_y)**2)
            ratio = distance / max_radius

            # Gradient from soft blue to purple
            r = int(100 + ratio * 80)      # 100-180
            g = int(150 - ratio * 70)       # 150-80
            b = int(220 - ratio * 20)       # 220-200

            img.putpixel((x, y), (r, g, b))

    # Draw concentric circles (breathing waves)
    num_circles = 5
    max_circle_radius = size * 0.4

    for i in range(num_circles):
        # Calculate radius with spacing
        radius = max_circle_radius * (i + 1) / num_circles

        # Calculate opacity (inner circles more opaque)
        opacity = int(255 * (1 - i / num_circles) * 0.5)

        # Circle color - white with varying opacity
        circle_color = (255, 255, 255, opacity)

        # Calculate bounding box
        left = center_x - radius
        top = center_y - radius
        right = center_x + radius
        bottom = center_y + radius

        # Draw circle outline
        draw.ellipse(
            [left, top, right, bottom],
            outline=(255, 255, 255, opacity),
            width=max(1, size // 100)
        )

    # Draw center dot
    center_radius = size * 0.08
    draw.ellipse(
        [center_x - center_radius, center_y - center_radius,
         center_x + center_radius, center_y + center_radius],
        fill=(255, 255, 255, 230)
    )

    return img

def generate_all_icons(output_dir):
    """Generate all required icon sizes."""
    os.makedirs(output_dir, exist_ok=True)

    print("🎨 Generating ZenFlow app icons...")

    for base_size, scale, filename in ICON_SPECS:
        pixel_size = int(base_size * scale)

        print(f"  Creating {filename} ({pixel_size}x{pixel_size})...")

        icon = create_zen_icon(pixel_size)
        output_path = os.path.join(output_dir, filename)
        icon.save(output_path, 'PNG', quality=100)

    print(f"✅ Successfully generated {len(ICON_SPECS)} icons!")
    print(f"📁 Icons saved to: {output_dir}")

if __name__ == "__main__":
    output_directory = "./ZenFlow/Assets.xcassets/AppIcon.appiconset/"
    generate_all_icons(output_directory)
