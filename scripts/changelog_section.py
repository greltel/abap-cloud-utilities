"""Print the CHANGELOG.md section of one version.

Usage: python scripts/changelog_section.py 1.2.0
       python scripts/changelog_section.py v1.2.0

Exit codes:
    0 - section found and printed
    1 - no section for that version
"""

import re
import sys
from pathlib import Path

CHANGELOG = Path(__file__).resolve().parent.parent / "CHANGELOG.md"


def section(version: str) -> str | None:
    heading = re.compile(rf"^## \[{re.escape(version)}\]")
    next_heading = re.compile(r"^## \[")
    lines = CHANGELOG.read_text(encoding="utf-8").splitlines()

    start = next((i for i, line in enumerate(lines) if heading.match(line)), None)
    if start is None:
        return None

    end = next((i for i in range(start + 1, len(lines)) if next_heading.match(lines[i])), len(lines))
    body = "\n".join(lines[start + 1:end]).strip()

    return body or None


def main() -> int:
    if len(sys.argv) != 2:
        print(__doc__, file=sys.stderr)
        return 1

    version = sys.argv[1].removeprefix("v")
    body = section(version)

    if body is None:
        print(f"::error::CHANGELOG.md has no section '## [{version}]' or it is empty", file=sys.stderr)
        return 1

    print(body)
    return 0


if __name__ == "__main__":
    sys.exit(main())
