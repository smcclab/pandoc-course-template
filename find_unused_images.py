#!/usr/bin/env python3
"""
Find images in lectures/img that are not referenced in any markdown file.
"""

import os
import re
from pathlib import Path

def find_markdown_files(lectures_dir):
    """Find all markdown files in the lectures directory."""
    return list(Path(lectures_dir).glob("*.md"))

def find_images(img_dir):
    """Find all image files in the img directory."""
    image_extensions = {'.png', '.jpg', '.jpeg', '.gif', '.svg', '.webp', '.bmp'}
    images = []
    
    img_path = Path(img_dir)
    if img_path.exists():
        for file in img_path.iterdir():
            if file.is_file() and file.suffix.lower() in image_extensions:
                images.append(file)
    
    return images

def extract_image_references(markdown_file):
    """Extract all image references from a markdown file."""
    with open(markdown_file, 'r', encoding='utf-8') as f:
        content = f.read()
    
    # Match markdown image syntax: ![alt](path)
    markdown_pattern = r'!\[.*?\]\((.*?)\)'
    
    # Match HTML img tags: <img src="path">
    html_pattern = r'<img[^>]+src=["\']([^"\']+)["\']'
    
    references = set()
    references.update(re.findall(markdown_pattern, content))
    references.update(re.findall(html_pattern, content))
    
    return references

def normalize_path(ref_path, base_dir):
    """Normalize a reference path to match actual file paths."""
    # Remove any leading ./
    ref_path = ref_path.lstrip('./')
    img_path = Path(ref_path)
    return img_path.name

def main():
    lectures_dir = "lectures"
    img_dir = os.path.join(lectures_dir, "img")
    
    # Find all markdown files and images
    md_files = find_markdown_files(lectures_dir)
    images = find_images(img_dir)
    
    if not md_files or not images:
        return
    
    print(f"Found {len(md_files)} markdown files")
    print(f"Found {len(images)} images")
    
    # Collect all image references from all markdown files
    all_references = set()
    for md_file in md_files:
        refs = extract_image_references(md_file)
        normalized_refs = {normalize_path(ref, lectures_dir) for ref in refs}
        all_references.update(normalized_refs)
    
    print(f"Found {len(all_references)} unique image references\n")

    # print(all_references)
    
    # Find unused images
    unused_images = []
    for img in images:
        if img.name not in all_references:
            print(img.name)
            unused_images.append(img)
    
    # Display results
    # if unused_images:
    #     print(f"Found {len(unused_images)} unused images:\n")
    #     for img in sorted(unused_images):
    #         print(img)

if __name__ == "__main__":
    main()
