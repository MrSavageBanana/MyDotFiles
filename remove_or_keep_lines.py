import sys
import os

def main():
    if len(sys.argv) != 5:
        print("Usage: remove_or_keep_lines.py <1|2> <input_file> <output_file> <string>")
        print("1 = remove lines containing string")
        print("2 = keep only lines containing string")
        return

    choice = sys.argv[1]
    input_file = sys.argv[2]
    output_file = sys.argv[3]
    pattern = sys.argv[4]

    if choice not in ("1", "2"):
        print("Error: First parameter must be 1 (remove) or 2 (keep).")
        return

    # Explicit filename existence check (handles weird names safely)
    if not os.path.exists(input_file):
        print(f"Error: Input file '{input_file}' not found.")
        return

    try:
        with open(input_file, "r", encoding="utf-8", errors="ignore") as infile, \
             open(output_file, "w", encoding="utf-8") as outfile:

            for line in infile:
                if choice == "1":
                    if pattern not in line:
                        outfile.write(line)
                else:
                    if pattern in line:
                        outfile.write(line)

        print(f"Done. Output written to {output_file}")

    except Exception as e:
        print(f"Error: {e}")


if __name__ == "__main__":
    main()
