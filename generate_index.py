#!/usr/bin/env python3
"""
Builds a very simple index.html page with links to each html file in the build directory.
Uses data in _config.toml for title, author, and institution.
"""
import sys
import tomllib
from pathlib import Path
import re


def get_html_page_title(html_path: Path) -> str:
    """
    Extract the page title from an HTML file using regex.
    """
    with html_path.open('r', encoding='utf-8') as file:
        content = file.read()
    match = re.search(r'<title[^>]*>(.*?)</title>', content, re.IGNORECASE | re.DOTALL)
    if match:
        title = match.group(1)
        title = re.sub(r'\s+', ' ', title).strip()
        return title
    else:
        return ""


def generate_index(info: dict, base_path: Path) -> str:
    """Generate HTML index page with links to built files"""
    title = info["title"]
    institution = info["institution"]
    author = info["author"]
    html = f"""<!DOCTYPE html>
<html>
<head>
    <title>{title}</title>
    <style>
        body {{ font-family: Arial, sans-serif; max-width: 800px; margin: 2em auto; padding: 0 1em; background-color: #1a1a1a; color: #e0e0e0;}}
        h1 {{ color: #ffffff; }}
        ol {{ line-height: 1.6; }}
        a {{ color: #66b3ff; text-decoration: none;}}
        a:hover {{ text-decoration: underline; color: #99ccff;}}
    </style>
</head>
<body>
    <h1>{title}</h1>
    <h3>{author}</h3>
    <h3>{institution}</h3>
"""
    
    # subdirectories of the base_path are the headings.
    subdirectories = [item for item in base_path.iterdir() if item.is_dir()]
    for dir in sorted(subdirectories):
        dir_name = dir.name
        print(f"Processing directory: {dir_name}")
        html_files = list(dir.rglob('*.html'))
        html += f'    <h4>{dir_name}</h4>\n'

        # html files contained within dir are the list items.
        html += f'    <ol>\n'
        for html_path in sorted(html_files):
            print(f"  Processing HTML file: {html_path}")
            html += html_file_li_string(html_path, base_path)
        html += f'    </ol>\n'


    html += """
</body>
</html>"""
    return html


def html_file_li_string(html_path: Path, base_path: Path) -> str:
    """
    Writes a <li> str related to a single html document in the index. Searches for possible extra files (pdf, docx, pptx)
    """
    out = "        <li>"
    out += get_html_page_title(html_path)
    html_rel_path = str(html_path.relative_to(base_path))
    out += f' [<a href="{html_rel_path}">html</a>]'
    # link PDF if it exists
    pdf_path = html_path.with_suffix(".pdf")
    if pdf_path.exists():
        out += f' [<a href="{str(pdf_path.relative_to(base_path))}">pdf</a>]'
    # link docx if it exists
    docx_path = html_path.with_suffix(".docx")
    if docx_path.exists():
        out += f' [<a href="{str(docx_path.relative_to(base_path))}">docx</a>]'
    # link pptx if it exists
    pptx_path = html_path.with_suffix(".pptx")
    if pptx_path.exists():
        out += f' [<a href="{str(pptx_path.relative_to(base_path))}">pptx</a>]'
    out+= "</li>\n"
    return out


if __name__ == '__main__':
    if len(sys.argv) < 2:
        print("Usage: script.py output_file build_directory")
        sys.exit(1)
    
    with open("_config.toml", "rb") as f:
        info = tomllib.load(f)

    output_file = Path(sys.argv[1]) # output file
    base_dir = Path(sys.argv[2]) # base dir

    with open(output_file, 'w') as f:
        f.write(generate_index(info, base_dir))
