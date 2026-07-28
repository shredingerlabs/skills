# AFK Loop

Drive an opencode agent through a queue of ready-for-agent tickets on GitHub or GitLab.

## Language

**Ticket** (also "issue"):
An item in the GitHub/GitLab issue tracker with a number, title, labels, and body.
_Avoid_: Task, item, work-item

**Title prefix**:
The portion of an issue title before the first colon (e.g. `T-K02` in `T-K02: Add login`).
Used as the sort key in title mode.

**Prefix guard**:
A string (default `T-K`) that an issue title must start with to be considered in title mode.
Rejects unrelated issues that happen to sort into the range.

**Ready label**:
The label that marks a ticket as ready for the agent to process (`--ready-label`, default `ready-for-agent`).

**Blocked by**:
A line in the issue body of the form `Blocked by: #N`. The script skips tickets with open blockers.
