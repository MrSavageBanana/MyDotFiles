#!/usr/bin/env python3
"""
LaTeX/TikZ to SVG Converter
Converts LaTeX equations and TikZ diagrams to SVG images for use in Google Docs.

Usage:
    python latex2svg.py input.tex -o output.svg
    echo '$E = mc^2$' | python latex2svg.py --stdin -o equation.svg
"""

import argparse
import subprocess
import tempfile
import shutil
import sys
import re
from pathlib import Path

# Minimal LaTeX template
LATEX_TEMPLATE = r"""\documentclass[border=2pt]{{standalone}}
\usepackage{{amsmath}}
\usepackage{{amssymb}}
\usepackage{{tikz}}
\usetikzlibrary{{arrows.meta,positioning,shapes}}
\begin{{document}}
{content}
\end{{document}}
"""


def check_dependencies(crop=False):
    """Check if required tools are installed."""
    required = ["pdflatex", "pdf2svg"]
    if crop:
        required.append("pdfcrop")

    missing = []

    for tool in required:
        if not shutil.which(tool):
            missing.append(tool)

    if missing:
        print(f"Error: Missing required tools: {', '.join(missing)}", file=sys.stderr)
        print("\nInstallation instructions:", file=sys.stderr)
        print(
            "  Ubuntu/Debian: sudo apt-get install texlive-latex-base texlive-pictures texlive-extra-utils pdf2svg",
            file=sys.stderr,
        )
        print(
            "  macOS: brew install --cask mactex && brew install pdf2svg",
            file=sys.stderr,
        )
        print("  Windows: Install MiKTeX + pdf2svg", file=sys.stderr)
        return False
    return True


def is_complete_document(content):
    """Check if content is already a complete LaTeX document."""
    return r"\documentclass" in content


def clean_content(content):
    """Remove preamble and document commands from partial documents."""
    # Remove \usepackage commands (they're in the template)
    content = re.sub(r"\\usepackage(\[.*?\])?\{.*?\}\s*", "", content)

    # Remove \begin{document} and \end{document}
    content = content.replace(r"\begin{document}", "")
    content = content.replace(r"\end{document}", "")

    # Remove display math delimiters \[ and \] (incompatible with tikzpicture)
    content = content.replace(r"\[", "")
    content = content.replace(r"\]", "")

    # Also remove $$ delimiters if present
    content = content.replace("$$", "")

    return content.strip()


def wrap_content(content, is_equation=False):
    """Wrap content in appropriate LaTeX environment."""
    content = content.strip()

    # If it's inline math ($ ... $) or display math ($$ ... $$), use as-is
    if content.startswith("$") and content.endswith("$"):
        return content

    # If it's already in an environment, use as-is
    if content.startswith(r"\begin{"):
        return content

    # Otherwise, wrap appropriately
    if is_equation:
        return f"${content}$"
    else:
        return content


def latex_to_svg(
    latex_content, output_path, engine="pdflatex", crop=False, margin=10, verbose=False
):
    """Convert LaTeX content to SVG."""
    with tempfile.TemporaryDirectory() as tmpdir:
        tmpdir = Path(tmpdir)
        tex_file = tmpdir / "document.tex"
        pdf_file = tmpdir / "document.pdf"
        cropped_pdf = tmpdir / "document-crop.pdf"

        # Write LaTeX file - use as-is if complete, otherwise wrap
        if is_complete_document(latex_content):
            tex_file.write_text(latex_content)
        else:
            cleaned = clean_content(latex_content)
            tex_file.write_text(LATEX_TEMPLATE.format(content=cleaned))

        # Compile LaTeX to PDF
        cmd = [
            engine,
            "-interaction=batchmode",
            "-halt-on-error",
            f"-output-directory={tmpdir}",
            str(tex_file),
        ]

        if verbose:
            print(f"Running: {' '.join(cmd)}")

        result = subprocess.run(cmd, capture_output=True, text=True)

        if result.returncode != 0 or not pdf_file.exists():
            log_file = tmpdir / "document.log"
            if log_file.exists():
                print("LaTeX compilation failed. Log excerpt:", file=sys.stderr)
                log_content = log_file.read_text()
                # Print last 30 lines of log
                print("\n".join(log_content.split("\n")[-30:]), file=sys.stderr)
            else:
                print(f"LaTeX compilation failed: {result.stderr}", file=sys.stderr)
            return False

        # Crop PDF if requested
        pdf_to_convert = pdf_file
        if crop:
            cmd = ["pdfcrop", f"--margins={margin}", str(pdf_file), str(cropped_pdf)]

            if verbose:
                print(f"Running: {' '.join(cmd)}")

            result = subprocess.run(cmd, capture_output=True, text=True)

            if result.returncode == 0 and cropped_pdf.exists():
                pdf_to_convert = cropped_pdf
            else:
                print(
                    f"Warning: PDF cropping failed, using uncropped version",
                    file=sys.stderr,
                )

        # Convert PDF to SVG using pdf2svg
        cmd = ["pdf2svg", str(pdf_to_convert), str(output_path)]

        if verbose:
            print(f"Running: {' '.join(cmd)}")

        result = subprocess.run(cmd, capture_output=True, text=True)

        if result.returncode != 0:
            print(f"PDF to SVG conversion failed: {result.stderr}", file=sys.stderr)
            return False

        return True


def main():
    parser = argparse.ArgumentParser(
        description="Convert LaTeX/TikZ snippets to SVG images (auto-cropped to content)",
        formatter_class=argparse.RawDescriptionHelpFormatter,
        epilog="""
Examples:
  # From file
  python latex2svg.py equation.tex -o equation.svg
  
  # From stdin
  echo '$\\frac{a}{b}$' | python latex2svg.py --stdin -o frac.svg
  
  # Inline equation
  python latex2svg.py -e 'E = mc^2' -o einstein.svg
  
  # TikZ diagram
  python latex2svg.py tikz_diagram.tex -o diagram.svg

Note: The output is automatically cropped to fit just the content using the 
standalone document class with border=2pt padding.
        """,
    )

    input_group = parser.add_mutually_exclusive_group(required=True)
    input_group.add_argument("input", nargs="?", help="Input LaTeX file")
    input_group.add_argument("--stdin", action="store_true", help="Read from stdin")
    input_group.add_argument(
        "-e", "--equation", help="Inline equation (auto-wrapped in $ $)"
    )

    parser.add_argument("-o", "--output", required=True, help="Output SVG file")
    parser.add_argument(
        "--crop",
        action="store_true",
        help="Crop PDF to content before converting to SVG",
    )
    parser.add_argument(
        "--margin",
        type=int,
        default=10,
        help="Margin in pixels when cropping (default: 10)",
    )
    parser.add_argument(
        "--engine",
        default="pdflatex",
        choices=["pdflatex", "lualatex", "xelatex"],
        help="LaTeX engine to use (default: pdflatex)",
    )
    parser.add_argument("-v", "--verbose", action="store_true", help="Verbose output")

    args = parser.parse_args()

    # Check dependencies
    if not check_dependencies(crop=args.crop):
        return 1

    # Get content
    if args.stdin:
        content = sys.stdin.read()
    elif args.equation:
        content = wrap_content(args.equation, is_equation=True)
    else:
        try:
            content = Path(args.input).read_text()
        except FileNotFoundError:
            print(f"Error: Input file '{args.input}' not found", file=sys.stderr)
            return 1

    # Convert
    output_path = Path(args.output)
    output_path.parent.mkdir(parents=True, exist_ok=True)

    if args.verbose:
        print(f"Converting LaTeX to SVG{' (with cropping)' if args.crop else ''}...")
        print(f"Content:\n{content}\n")

    success = latex_to_svg(
        content, output_path, args.engine, args.crop, args.margin, args.verbose
    )

    if success:
        crop_msg = f" (cropped with {args.margin}px margin)" if args.crop else ""
        print(f"✓ SVG created{crop_msg}: {output_path}")
        return 0
    else:
        print("✗ Conversion failed", file=sys.stderr)
        return 1


if __name__ == "__main__":
    sys.exit(main())
