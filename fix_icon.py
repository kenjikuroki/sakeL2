import os
from PIL import Image

def analyze_and_regenerate(input_path, output_path):
    img = Image.open(input_path).convert("RGBA")
    width, height = img.size
    print(f"Original size: {width}x{height}")

    # Sample colors
    # Center (might be bottle)
    center_pixel = img.getpixel((width//2, height//2))
    
    # Mid-left (background?)
    mid_left_pixel = img.getpixel((width//4, height//2))
    
    # Top-left (corner - possibly transparent or white if rounded)
    corner_pixel = img.getpixel((0, 0))

    def to_hex(rgba):
        return "#{:02x}{:02x}{:02x}".format(rgba[0], rgba[1], rgba[2])

    print(f"Center pixel: {to_hex(center_pixel)}")
    print(f"Mid-Left pixel: {to_hex(mid_left_pixel)}")
    print(f"Corner pixel: {to_hex(corner_pixel)} (Alpha: {corner_pixel[3]})")

    # Strategy:
    # 1. We want the Dark Blue background. Looking at the icon, the bottle is in the middle.
    #    The area around the bottle is the dark blue. Mid-Left is likely a good candidate.
    #    Let's assume Mid-Left is the background color.
    bg_color_hex = to_hex(mid_left_pixel) 
    
    # 2. Resize
    # To make it "Full", we should NOT shrink it too much.
    # However, if we want the Gold Border to be visible, we need to fit it in the circle.
    # The Safe Zone is circle diameter = 66% of size. 
    # If the image is a square 100x100.
    # We want the square to be inside the circle? No, that would be tiny.
    # We want the square's corners to be just inside?
    # Or maybe the user wants the gold border to BE the frame?
    # If we make the background color match the dark blue, we can shrink the "Square with Gold Border"
    # just enough so it fits (or mostly fits) within the visible area, and the REST is filled with dark blue.
    # Then it looks like [Dark Blue Infinite Field] -> [Gold Border] -> [Dark Blue Inner] -> [Bottle].
    
    # Let's scale it so the square is slightly smaller than the full viewport?
    # Viewport is 108dp. Safe zone 66dp.
    # If we target the square to be say 75% of the viewport, it is 81dp. 
    # That is larger than safe zone (66dp) but safe zone is for CRITICAL content.
    # The border might be cut on some devices, but that's better than "Tiny".
    
    # Let's try scaling 100% -> 75% (0.75 factor, meaning padding = 1/0.75 = 1.33)
    # Previous was 1.5 (66%). 1.33 is bigger.
    # Let's try 1.25 (80%).
    
    padding_factor = 1.25 # Canvas will be 1.25x the image size. Image will be 80% of canvas.

    new_dim = int(max(width, height) * padding_factor)
    new_img = Image.new("RGBA", (new_dim, new_dim), (0, 0, 0, 0))
    
    paste_x = (new_dim - width) // 2
    paste_y = (new_dim - height) // 2
    new_img.paste(img, (paste_x, paste_y), img)
    
    new_img.save(output_path)
    print(f"Generated {output_path} with size {new_dim}x{new_dim}")
    print(f"Recommended Background: {bg_color_hex}")

if __name__ == "__main__":
    analyze_and_regenerate("assets/icon/sake_icon_premium_l2.png", "assets/icon/sake_icon_adaptive_foreground.png")
