# Title-based issue selection in afkLoop.sh

`afkLoop.sh` originally walked tickets by numeric issue number only (`--start N --end N`). We added an alternative **title mode** that selects issues by title prefix range (`--title-start T-K02 --title-end T-K05b`). The script queries all ready-labeled issues, extracts the portion of each title before the first `:`, compares it lexicographically against the range, sorts by prefix, shows the list, and walks it. An optional `--title-prefix` guard (default `T-K`) rejects issues whose title doesn't start with that string, preventing unrelated issues with similar prefixes from leaking in.

Title mode and numeric mode are mutually exclusive — passing both `--start` and `--title-start` is an error. This keeps the interface predictable and avoids confusing intersection semantics.
