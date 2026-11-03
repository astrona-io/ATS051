---
draft: true
exam_objectives:
- Configuring Alerting rules
---
# Validating Rules With promtool

`promtool` is the command-line tool that ships with Prometheus. It can check a rule file before the server loads it, and it can run a rule file against fabricated input series to confirm that an alert fires when it should. Both checks run without a Prometheus server, which makes them suitable for review pipelines.

## Checking Syntax

`promtool check rules` reads one or more rule files and reports whether they are valid.

```sh
promtool check rules rules.yaml
```

The check verifies that the YAML structure matches the rule file format, that every expression parses as PromQL, that label names are valid, and that annotation templates parse. It exits with a nonzero status and a message with the file and rule when it finds a problem. On success it prints the number of rules found per file and exits with status zero.

The check does not run the expressions. It cannot know whether a selector matches any series, whether a label exists, or whether the threshold is sensible. The rule with `status="5xx"` in an expression that only ever has `200` and `500` passes the syntax check completely.

`promtool check config` validates the main configuration file and, by default, also the rule files it lists under `rule_files`. Use it when the change touches the Prometheus configuration as well as the rules.

## Unit Tests For Rules

`promtool test rules` loads a test file that describes input series, a time to evaluate at, and the alerts or query results expected at that time. It then evaluates the rules against only that data.

```yaml
rule_files:
  - rules.yaml

evaluation_interval: 1m

tests:
  - interval: 1m
    input_series:
      - series: 'lab_requests_total{service="probe",status="200"}'
        values: '0+90x10'
      - series: 'lab_requests_total{service="probe",status="500"}'
        values: '0+10x10'
    alert_rule_test:
      - eval_time: 5m
        alertname: ProbeErrorRatioHigh
        exp_alerts:
          - exp_labels:
              severity: critical
            exp_annotations:
              summary: Probe error ratio is high
```

Run it with `promtool test rules tests.yaml`. The tool prints a failure with the expected and the actual alerts when they differ.

## Series Notation

The `values` field uses a compact notation to describe samples at each `interval` step.

- `a+bxn` starts at `a` and adds `b` for `n` further steps, so `0+90x10` gives eleven samples from 0 to 900.
- `a-bxn` subtracts instead of adds.
- `_` means no sample at that step, which creates a gap.
- `stale` marks the series as stale at that step.
- Plain numbers such as `1 1 1 0` give explicit values.

A counter increasing by 90 per step with a step of one minute is 1.5 requests per second. Match the unit of the notation to the rate window in the rule, because a window shorter than two intervals returns no result.

## What To Test

Useful tests cover three situations.

- The condition is true long enough, and the alert appears with the expected labels and annotations at `eval_time`.
- The condition is true for less than the `for` duration, and `exp_alerts` is empty at an earlier time.
- The inputs are missing or have different labels, and the alert does not fire or does fire according to the intended absent-data behaviour.

An `exp_alerts` list that is empty asserts that no alert is active at that time. Annotation values are compared after template expansion, so the test also checks templates.

## Testing Recording Rules

`promql_expr_test` evaluates an expression, including the name of a recorded series, at a time and compares the result with `exp_samples`.

```yaml
    promql_expr_test:
      - expr: service:lab_requests:rate10s
        eval_time: 5m
        exp_samples:
          - labels: 'service:lab_requests:rate10s{service="probe",status="500"}'
            value: 0.1667
```

The test file lists the rule file, so recording rules in it produce series that the expression test can query.

## Limits Of Offline Tests

A test uses the data you wrote. It proves that the rule logic matches your idea of the input, not that the real metric has those labels. Keep the fabricated series close to the real exposition, including label names and the presence of every status value. Real metric names and label sets should be copied from the API response of the running system.

Offline checks also cannot prove delivery. They do not involve Alertmanager, routing, silences or receivers.

## Where Checks Fit

A reasonable order is syntax check, unit test, load into a test Prometheus, then reload production. Each step catches a different class of problem: syntax errors, logic errors, selector mismatches, and delivery problems.

## Common pitfalls

> [!WARNING]
> A passing syntax check says nothing about selectors or data. A test with invented labels can pass while the real metric differs. A rate window shorter than two sample intervals in a test returns nothing.
