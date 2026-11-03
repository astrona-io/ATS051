---
draft: true
exam_objectives:
- Configuring Alerting rules
---
# Summary

Prometheus loads rule files listed in `rule_files`, evaluates each group on its own interval, and runs the rules of one group in file order. A rule placed after the rule it reads sees the current cycle, and groups run independently of each other. A reload that fails to parse keeps the old rules active.

`promtool check rules` proves that a file is syntactically valid but not that its selectors match data. `promtool test rules` evaluates rules against fabricated series and compares the alerts and samples with expectations.

When a rule does not alert, read evidence in order: whether the rule is loaded, its health and last error, whether the expression returns data, whether the alert is pending and for how long, the combined delays, and whether the alert reached Alertmanager. An empty result is healthy, so health alone does not show a correct rule.

<!-- astrona:playground:destroy -->
