from PIL import Image
import os

def create_flat_icon(input_path, output_path, bg_color_hex):
    print(f"Processing: {input_path}")
    try:
        img = Image.open(input_path).convert("RGBA")
        width, height = img.size
        
        # Create background
        bg_color = (
            int(bg_color_hex[1:3], 16),
            int(bg_color_hex[3:5], 16),
            int(bg_color_hex[5:7], 16),
            255
        )
        new_img = Image.new("RGBA", (width, height), bg_color)
        
        # Composite foreground onto background
        new_img.paste(img, (0, 0), img)
        
        # Save
        new_img.save(output_path)
        print(f"Created flat icon at: {output_path}")
        
    except Exception as e:
        print(f"Error: {e}")

if __name__ == "__main__":
    create_flat_icon(
        "/Users/kurok/StudioProjects/SAKE/Sake_Exam_L2/assets/icon/sake_icon_adaptive_foreground_v2.png", 
        "assets/icon/sake_icon_flat.png", 
        "#141227"
    )
