# scripts/capture-screenshot.py - Terminal Screenshot Generator & Screen Grabber
import sys
import os
import argparse
from datetime import datetime
from PIL import Image, ImageDraw, ImageFont

def render_terminal_screenshot(command_text, output_text, title, output_path, status="SUCCESS"):
    # Window dimensions
    width = 1200
    padding = 30
    line_spacing = 22
    
    # Split text into lines
    cmd_lines = command_text.strip().split("\n")
    out_lines = output_text.strip().split("\n")
    all_lines = ["$ " + cmd_lines[0]] + ["> " + l for l in cmd_lines[1:]] + [""] + out_lines
    
    # Calculate required height
    content_height = len(all_lines) * line_spacing + 120
    height = max(500, min(2400, content_height))
    
    # Create dark-mode terminal background
    img = Image.new("RGB", (width, height), color=(15, 17, 26))
    draw = ImageDraw.Draw(img)
    
    # Title bar
    draw.rectangle([(0, 0), (width, 45)], fill=(28, 33, 48))
    
    # Window controls (macOS / Linux style dots)
    draw.ellipse([(18, 16), (30, 28)], fill=(255, 95, 86))   # Red
    draw.ellipse([(38, 16), (50, 28)], fill=(255, 189, 46))  # Yellow
    draw.ellipse([(58, 16), (70, 28)], fill=(39, 201, 63))   # Green
    
    # Title & Badge
    try:
        font = ImageFont.truetype("consola.ttf", 15)
        font_bold = ImageFont.truetype("consolab.ttf", 15)
        font_title = ImageFont.truetype("segoeui.ttf", 14)
    except:
        font = ImageFont.load_default()
        font_bold = font
        font_title = font
        
    title_str = f"sathvik-devsecops ~ {title}  |  AWS: 009160054307 (us-east-1)  |  profile: sathvik-dev"
    draw.text((90, 14), title_str, fill=(180, 190, 205), font=font_title)
    
    # Status badge on right
    status_color = (39, 201, 63) if status == "SUCCESS" else (255, 95, 86) if status == "FAILURE" else (255, 189, 46)
    draw.rectangle([(width - 140, 10), (width - 20, 35)], fill=(35, 42, 60))
    draw.text((width - 125, 14), status, fill=status_color, font=font_bold)
    
    # Render command and output text
    y = 65
    for i, line in enumerate(all_lines):
        if y > height - 40:
            break
        if line.startswith("$ "):
            draw.text((padding, y), line, fill=(79, 195, 247), font=font_bold) # Cyan for command
        elif line.startswith("> "):
            draw.text((padding, y), line, fill=(100, 210, 255), font=font_bold)
        elif "ERROR" in line or "FAIL" in line or "CRITICAL" in line or "SubscriptionRequired" in line:
            draw.text((padding, y), line, fill=(255, 110, 110), font=font) # Red for errors/findings
        elif "PASS" in line or "SUCCESS" in line or "AVAILABLE" in line or "Created" in line or "OK" in line:
            draw.text((padding, y), line, fill=(120, 220, 140), font=font) # Green for success
        elif "WARN" in line or "HIGH" in line:
            draw.text((padding, y), line, fill=(255, 200, 80), font=font) # Yellow for warnings
        else:
            draw.text((padding, y), line, fill=(210, 215, 225), font=font) # Normal light gray
        y += line_spacing

    # Footer
    timestamp_str = datetime.now().strftime("%Y-%m-%d %H:%M:%S UTC")
    draw.text((padding, height - 25), f"Verified DevSecOps Execution - {timestamp_str}", fill=(100, 110, 130), font=font)

    os.makedirs(os.path.dirname(output_path), exist_ok=True)
    img.save(output_path, "PNG")
    print(f"[SCREENSHOT SAVED] {output_path}")

if __name__ == "__main__":
    parser = argparse.ArgumentParser()
    parser.add_argument("--command", required=True)
    parser.add_argument("--output", required=True)
    parser.add_argument("--title", required=True)
    parser.add_argument("--file", required=True)
    parser.add_argument("--status", default="SUCCESS")
    args = parser.parse_args()
    
    with open(args.file, "r", encoding="utf-8", errors="replace") as f:
        content = f.read()
        
    render_terminal_screenshot(args.command, content, args.title, args.output, args.status)
