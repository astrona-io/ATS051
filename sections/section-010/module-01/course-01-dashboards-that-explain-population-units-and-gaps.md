---
draft: true
exam_objectives:
- Dashboarding basics
---
# Dashboards That Explain Population, Units And Gaps

A dashboard is a view of evidence chosen to support an operational decision. It can summarize a fleet, locate an affected service or follow a known incident. A useful panel makes its population and unit understandable and does not hide collection gaps behind reassuring presentation.

## Start With The Audience's Question

A service overview often combines traffic, errors, duration and saturation. Traffic shows activity, errors show failed outcomes, duration shows responsiveness and saturation shows pressure on constrained resources. Their relationship can distinguish a load increase from a dependency outage more effectively than one unlabeled average.

A detailed incident view may retain instance or route dimensions that an overview aggregates. Choose the level appropriate to the question. A global total can hide one failed region, while dozens of individual lines can obscure a fleet-wide trend. Grouping should preserve the distinctions needed for the intended decision.

## State Units And Population

Panel titles, axes and legends should make the measured quantity clear. Requests per second differ from a cumulative request count. Seconds differ from milliseconds. A latency percentile differs from a mean and has distribution-resolution limits. Incorrect unit formatting can make an otherwise correct expression appear dramatically different.

For ratios, explain the denominator. A 10% failure rate based on ten requests has a different evidence volume from the same percentage based on millions. Pair the ratio with traffic when low-volume behavior matters. Preserve ownership labels and avoid combining unrelated environments through a permissive dashboard variable.

## Time Range And Resolution Shape The View

The displayed time range determines which evaluation times are requested. Query step or resolution determines how often an expression is evaluated within that range. The expression's rate window remains a separate setting. Changing one does not automatically change the others.

A short step cannot create observations between source scrapes. A long step can omit brief behavior from the displayed evaluation points. A long rate window can smooth a recent spike even when the panel refreshes rapidly. State the relevant settings so viewers do not mistake display responsiveness for collection precision.

## Preserve Missing-Data Meaning

A gap can reflect absent samples, staleness, failed collection or a selector that no longer matches changed labels. Zero can be a real measured value. Filling every gap with zero can hide a collector outage or make a missing error numerator appear healthy. Use presentation that preserves the distinction unless a justified measurement model supports a fallback.

A series disappearing after replacement may indicate a changed instance identity rather than data deletion. Inspect grouping and labels before deciding the application stopped. Duplicate replica or scrape-job data can also distort totals, so a panel should rely on a deliberate source selection and deduplication model where needed.

## Connect The View To Action

Dashboards can provide context for an alert, but they do not define the alert's evaluation or notification pipeline automatically. A panel threshold color does not establish that an alert rule exists, is firing or reached a receiver. Show rule and notification evidence separately when those states matter.

Keep the view focused on actionable interpretation and give viewers enough context to ask the next diagnostic question. A large number of panels is not inherently better observability. Review whether each calculation answers a real question and whether the display preserves its limitations.

## Common pitfalls

> [!WARNING]
> Dashboard refresh does not create samples, and a threshold color is not alert delivery evidence. Preserve units, denominator context and the distinction between missing data and observed zero.
