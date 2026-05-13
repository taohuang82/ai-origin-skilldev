"""
自动在默认浏览器中打开 HTML 文件进行预览。
用法: python scripts/open_preview.py <html文件路径>
兼容 Windows / macOS / Linux。
"""
import sys
import os
import webbrowser
from pathlib import Path


def main():
    if len(sys.argv) < 2:
        print("用法: python scripts/open_preview.py <html文件路径>")
        sys.exit(1)

    filepath = Path(sys.argv[1]).resolve()

    if not filepath.exists():
        print(f"文件不存在: {filepath}")
        sys.exit(1)

    if not filepath.suffix.lower() in ('.html', '.htm'):
        print(f"不是 HTML 文件: {filepath}")
        sys.exit(1)

    url = filepath.as_uri()
    print(f"正在打开浏览器预览: {url}")
    webbrowser.open(url)


if __name__ == '__main__':
    main()
