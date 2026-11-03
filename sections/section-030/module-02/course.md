---
draft: true
exam_objectives:
- Understand and Use Alertmanager
---
# Inhibition, Receivers And High Availability

The first stages of Alertmanager choose a route and a group. This module covers what happens next: which notifications are dropped because a more important alert already covers them, how a receiver turns a group into a message for a person or a system, how several Alertmanager instances avoid sending the same message twice, and how to operate the service from the command line and the API.

## Learning Goals

- Write an inhibition rule with source matchers, target matchers and an `equal` list, and predict which alerts it suppresses.
- Configure webhook and other receivers and write a notification template with the Go templating language.
- Explain how an Alertmanager cluster shares silences and notification logs, and what it does not guarantee.
- Use `amtool` and the v2 API to list alerts, create and expire silences, validate a configuration file and test a route.

## Before You Start

The playground is a kind cluster. A kind cluster is a Kubernetes cluster that runs inside containers on your machine. It runs Prometheus, an instrumented `probe` service whose webhook endpoint stores every notification body it receives, and an Alertmanager configured through the `alertmanager-config` ConfigMap. You change the configuration by editing the ConfigMap and restarting the Alertmanager Deployment.

## Reading Order

1. Inhibition Rules
2. Receivers And Notification Templates
3. High Availability Clustering
4. amtool And The API
5. Summary

<!-- astrona:playground -->
