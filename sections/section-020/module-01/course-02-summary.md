---
draft: true
exam_objectives:
- Configuring Alerting rules
---
# Summary

An alert rule creates instances from the label sets returned by its expression. Persistence requirements can keep an instance pending until its condition remains active long enough, while unstable labels or missing results can interrupt that continuity.

Labels identify and route alerts; annotations explain their context. Rule firing is separate from notification, and expressions must handle zero-valued present results and missing data according to their actual semantics.
