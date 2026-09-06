import sys

from boltons.strutils import slugify


def main() -> None:
    print(slugify(sys.argv[1], delim="-", ascii=True).decode())


if __name__ == "__main__":
    main()
