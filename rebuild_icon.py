import os
from PIL import Image

def process_icon(input_path, output_path):
    print(f"Processing: {input_path}")
    img = Image.open(input_path).convert("RGBA")
    width, height = img.size
    
    # 1. Remove White Corners (Flood Fill)
    # The user says "White margins". The original image likely has white corners.
    # We will make them transparent so the Dark Blue background shows through.
    
    # Get corner color
    corner_color = img.getpixel((0, 0))
    print(f"Corner color: {corner_color}")
    
    # Simple threshold flood fill from 4 corners
    # BFS approach for flood fill
    def flood_fill_transparent(image, start_x, start_y, target_color, tolerance=30):
        pixels = image.load()
        w, h = image.size
        
        # Check if start is already transparent or not target
        start_px = pixels[start_x, start_y]
        if start_px[3] == 0: return # Already transparent
        
        def color_match(c1, c2):
            return sum(abs(a - b) for a, b in zip(c1[:3], c2[:3])) < tolerance

        if not color_match(start_px, target_color):
            return # Start pixel doesn't match target

        queue = [(start_x, start_y)]
        visited = set([(start_x, start_y)])
        
        # Make start transparent
        pixels[start_x, start_y] = (0, 0, 0, 0)
        
        while queue:
            x, y = queue.pop(0)
            
            for dx, dy in [(-1,0), (1,0), (0,-1), (0,1)]:
                nx, ny = x + dx, y + dy
                if 0 <= nx < w and 0 <= ny < h:
                    if (nx, ny) not in visited:
                        px = pixels[nx, ny]
                        if px[3] > 0 and color_match(px, target_color):
                            pixels[nx, ny] = (0, 0, 0, 0)
                            visited.add((nx, ny))
                            queue.append((nx, ny))

    # If the corner is functionally white/off-white, remove it.
    if corner_color[0] > 200 and corner_color[1] > 200 and corner_color[2] > 200:
        print("Detected light corners. Removing...")
        flood_fill_transparent(img, 0, 0, corner_color)
        flood_fill_transparent(img, width-1, 0, corner_color)
        flood_fill_transparent(img, 0, height-1, corner_color)
        flood_fill_transparent(img, width-1, height-1, corner_color)
    else:
        print("Corner is not light. Skipping flood fill.")

    # 2. Maximize Size
    # To make it "Full", we want the bounding box of the actual content (bottle + gold ring) 
    # to be as large as possible within the adaptive icon viewport.
    # The viewport is 108dp. Safe zone is 66dp diameter.
    # If the gold ring is critical, it must fit in 66dp? No, that makes it small.
    # The user wants it "Full".
    # We will assume the "Gold Ring" is the border.
    # We'll just save this processed image.
    # BUT, we need to ensure the canvas size is appropriate.
    # If we just save `img`, flutter_launcher_icons will scale it to fit the foreground layer.
    # Which is fine. We basically just want to remove the white corners.
    
    # However, if there is empty transparent space inside the image file (padding), we should crop it.
    bbox = img.getbbox()
    if bbox:
        print(f"Cropping to content: {bbox}")
        img = img.crop(bbox)
        
    # Now, to make it "Big", we can just output this.
    # The flutter_launcher_icons tool effectively centers the foreground.
    # If we want to "zoom in" past the safe zone safe-guards, we might need to add negative padding? 
    # Or just let it be. Cropping to content is the best "Max Size" we can do without losing parts.
    
    img.save(output_path)
    print(f"Saved processed icon to {output_path}")

if __name__ == "__main__":
    process_icon("assets/icon/sake_icon_premium_l2.png", "assets/icon/sake_icon_adaptive_foreground_v2.png")
