#!/usr/bin/python
import glob, os

def main() -> None:
    working_dir = os.path.join(os.path.curdir, "markdown")
    with open("result.md", "w") as result:
        for path in glob.glob(os.path.join(working_dir, "[0-9]*.md")):
            with open(path) as file:
                print(path)
                result.writelines(file.readlines())
                result.write("\n\n")

if __name__ == "__main__":
    main()