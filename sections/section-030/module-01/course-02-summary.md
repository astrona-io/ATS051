---
draft: true
exam_objectives:
- Understand and Use Alertmanager
---
# Summary

Alertmanager receives alert instances and manages notification routing, grouping and suppression. Routing labels and grouping choices determine ownership and how related failures are presented.

Silences and inhibition suppress notifications under different conditions without making source metrics healthy. Delivery and clustering need their own evidence; notification timing is distinct from the rule's persistence requirement and does not promise universal exactly-once behavior.
