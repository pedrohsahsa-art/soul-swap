# Release workflow

- User standing instruction: whenever a new version is completed, automatically commit the release changes, push to `https://github.com/pedrohsahsa-art/soul-swap`, and publish its tester prerelease. Do not require another publication request.
- Run appropriate tests and GitHub checks before publishing. Use a new version/tag; preserve existing releases.
- Package only allowlisted mod sources and documentation. Never commit game files, extracted assets, downloaded tools, logs or credentials.
- Inspect remote changes before updating; never force-push or overwrite others' work.
- Include the ZIP and its SHA-256 checksum in the release, verify the public download, and report the release link.
- If authentication or checks fail, report the blocker without claiming publication succeeded.
