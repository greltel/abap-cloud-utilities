#!/usr/bin/env python3
"""Check this repository's abapGit object filenames against every project
listed on dotabap.org.

The dotabap.org cron job fails when two listed projects ship a file with the
same name. This script reproduces that check locally so a collision is caught
here instead of in a bug report.

Exit codes:
    0 - no collision
    1 - at least one filename is also used by another listed project
    2 - the dotabap list could not be retrieved
"""

from __future__ import annotations

import io
import json
import os
import sys
import tarfile
import urllib.error
import urllib.request
from collections import defaultdict
from concurrent.futures import ThreadPoolExecutor

LIST_URL = "https://raw.githubusercontent.com/dotabap/dotabap-list/master/list.json"
SOURCE_DIR = "src"
WORKERS = 8
TIMEOUT = 45

# Files every abapGit repository ships; dotabap does not treat them as clashes.
IGNORED = {"package.devc.xml", ".abapgit.xml"}

SELF = os.environ.get("GITHUB_REPOSITORY", "greltel/abap-cloud-utilities")
TOKEN = os.environ.get("GITHUB_TOKEN", "")


def _get(url: str, accept: str = "") -> bytes:
    request = urllib.request.Request(url)
    if accept:
        request.add_header("Accept", accept)
    if TOKEN and "api.github.com" in url:
        request.add_header("Authorization", f"Bearer {TOKEN}")
    with urllib.request.urlopen(request, timeout=TIMEOUT) as response:
        return response.read()


def is_object_file(name: str) -> bool:
    return name.endswith((".abap", ".xml")) and name not in IGNORED


def own_filenames() -> set[str]:
    found = set()
    for root, _dirs, files in os.walk(SOURCE_DIR):
        for name in files:
            if is_object_file(name.lower()):
                found.add(name.lower())
    return found


def default_branch(repo: str) -> str | None:
    try:
        meta = json.loads(_get(f"https://api.github.com/repos/{repo}"))
        return meta.get("default_branch")
    except Exception:
        return None


def filenames_of(repo: str) -> tuple[str, set[str], bool]:
    """Return the object filenames of one repository."""
    branches = ["main", "master"]
    fallback = default_branch(repo) if TOKEN else None
    if fallback and fallback not in branches:
        branches.append(fallback)

    for branch in branches:
        url = f"https://codeload.github.com/{repo}/tar.gz/refs/heads/{branch}"
        try:
            archive = tarfile.open(fileobj=io.BytesIO(_get(url)), mode="r:gz")
        except (urllib.error.URLError, urllib.error.HTTPError, tarfile.TarError, OSError):
            continue
        names = {
            member.split("/")[-1].lower()
            for member in archive.getnames()
            if is_object_file(member.split("/")[-1].lower())
        }
        return repo, names, True

    return repo, set(), False


def main() -> int:
    try:
        projects = json.loads(_get(LIST_URL))
    except Exception as error:  # noqa: BLE001 - the list is the one hard dependency
        print(f"::error::could not download the dotabap list: {error}")
        return 2

    others = [repo for repo in projects if repo.lower() != SELF.lower()]
    mine = own_filenames()
    print(f"checking {len(mine)} object files against {len(others)} dotabap projects")

    collisions: dict[str, list[str]] = defaultdict(list)
    unreachable: list[str] = []

    with ThreadPoolExecutor(max_workers=WORKERS) as pool:
        for repo, names, reached in pool.map(filenames_of, others):
            if not reached:
                unreachable.append(repo)
                continue
            for name in mine & names:
                collisions[name].append(repo)

    if unreachable:
        print(f"::warning::{len(unreachable)} project(s) could not be read: {', '.join(sorted(unreachable))}")

    summary = os.environ.get("GITHUB_STEP_SUMMARY")
    lines = []

    if not collisions:
        message = f"No filename collisions. All {len(mine)} object files are unique across dotabap.org."
        print(message)
        lines.append(f"### Name collision check\n\n{message}\n")
    else:
        print(f"::error::{len(collisions)} filename(s) already used by another dotabap project")
        lines.append("### Name collision check\n")
        lines.append(f"**{len(collisions)} filename(s) collide.** Rename the objects below.\n")
        lines.append("| File | Also used by |")
        lines.append("| --- | --- |")
        for name in sorted(collisions):
            owners = ", ".join(sorted(collisions[name]))
            print(f"  {name}  ->  {owners}")
            lines.append(f"| `{name}` | {owners} |")

    if summary:
        with open(summary, "a", encoding="utf-8") as handle:
            handle.write("\n".join(lines) + "\n")

    return 1 if collisions else 0


if __name__ == "__main__":
    sys.exit(main())
