"""Generate the Pages download catalog from the GitHub Releases API."""

import json
import os
import re
import sys
from datetime import datetime
from urllib.parse import quote

TAG = re.compile(r"v\d+\.\d+\.\d+(?:-[0-9A-Za-z.-]+)?(?:\+\d+)?")
ASSETS = {
    "nodeql-workshop-admin-macos.zip": "macos",
    "nodeql-workshop-admin-windows-x64.zip": "windows",
    "nodeql-workshop-admin-linux-x64.tar.gz": "linux",
    "SHA256SUMS.txt": "checksum",
}


def catalog(pages, repository):
    base_url = f"https://github.com/{repository}/releases"
    releases = []
    for page in pages:
        for release in page:
            tag = release["tag_name"]
            published_at = release["published_at"]
            if release["draft"] or not published_at or not TAG.fullmatch(tag):
                continue
            release_tag = quote(tag, safe="")
            assets = {
                ASSETS[asset["name"]]: (
                    f"{base_url}/download/{release_tag}/{asset['name']}"
                )
                for asset in release["assets"]
                if asset["name"] in ASSETS and asset["state"] == "uploaded"
            }
            releases.append({
                "tag": tag,
                "published_at": published_at,
                "prerelease": release["prerelease"],
                "url": f"{base_url}/tag/{release_tag}",
                "assets": assets,
            })
    return sorted(
        releases,
        key=lambda release: datetime.fromisoformat(release["published_at"]),
        reverse=True,
    )


if __name__ == "__main__":
    json.dump(catalog(json.load(sys.stdin), os.environ["GITHUB_REPOSITORY"]), sys.stdout)
    print()
