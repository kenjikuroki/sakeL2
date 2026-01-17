import os
from PIL import Image

def generate_adaptive_icon(input_path, output_path, padding_ratio=0.33):
    """
    Resizes the input image to act as a foreground for adaptive icons.
    Adds transparent padding around the original image so it fits in the safe zone.
    Returns the detected background color (hex string).
    """
    try:
        img = Image.open(input_path).convert("RGBA")
        
        # Calculate new size
        original_width, original_height = img.size
        
        # The content should fit within the safe zone (center 66% diameter)
        # So we create a larger canvas.
        # If original is 100%, and we want it to be 66%, the new size should be original / 0.66
        # But commonly we just want to ensure the critical content (the whole image in this case) isn't cut.
        # A factor of 1.5 (1/0.66) is safe. Let's use 1.5.
        
        new_dimension = int(max(original_width, original_height) * 1.5)
        
        # Create new transparent image
        new_img = Image.new("RGBA", (new_dimension, new_dimension), (0, 0, 0, 0))
        
        # Paste original in center
        paste_x = (new_dimension - original_width) // 2
        paste_y = (new_dimension - original_height) // 2
        
        new_img.paste(img, (paste_x, paste_y), img)
        
        # Save
        new_img.save(output_path)
        print(f"Created adaptive foreground at: {output_path}")
        
        # Attempt to detect background color from top-left pixel
        # If transparent, fallback to black or ask user. 
        # But usually these icons might have a bg.
        bg_color = img.getpixel((0, 0))
        
        # If it's transparent, we probably want a specific color.
        # Let's check opacity.
        if bg_color[3] == 0:
            print("Detected transparent background. Defaulting to black #000000")
            return "#000000"
        
        def to_hex(rgba):
            return "#{:02x}{:02x}{:02x}".format(rgba[0], rgba[1], rgba[2])
            
        detected_hex = to_hex(bg_color)
        print(f"Detected background color: {detected_hex}")
        return detected_hex

    except Exception as e:
        print(f"Error: {e}")
        return None

if __name__ == "__main__":
    input_file = "assets/icon/sake_icon_premium_l2.png"
    output_file = "assets/icon/sake_icon_adaptive_foreground.png"
    
    # Ensure directory exists
    os.makedirs(os.path.dirname(output_file), exist_ok=True)
    
    generate_adaptive_icon(input_file, output_file)
