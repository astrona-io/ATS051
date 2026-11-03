# Configuring Alerting rules

This section covers writing, grouping, validating and troubleshooting Prometheus alerting and recording rules.

## Modules

| Module | Topic | Reading | Lab |
| --- | --- | --- | --- |
| module-01 | Alert Expressions, Pending State And Stable Labels | Rule anatomy, labels and templates, recording rules, guided practice | Repair or build alert rules and a recording rule |
| module-02 | Rule Groups, Evaluation And Validation | Groups and evaluation, promtool, troubleshooting | Repair an alert rule that never fires |

## Capstone

`capstone/labs/lab-01` asks for one rule group with a recording rule and an alert that reads the recorded series.

## Knowledge check

`quiz.yaml` holds the section question bank.

## Learning Outcomes

- Explain when an expression creates an alert instance and how pending and firing differ.
- Separate alert labels from annotations and write annotation templates.
- Write a recording rule and use it in an alert.
- Describe how rule groups are loaded, scheduled and evaluated.
- Validate rules with promtool and find why a loaded rule does not fire.

Labs and playgrounds are UNTESTED. They were checked statically only.
