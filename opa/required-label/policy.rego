package fairwinds

contains(colors, elem) {
  colors[_] = elem
}

labelRequired[actionItem] {
  labels = { x | input.metadata.labels[x] }
  not contains(labels, "costCenterCode")

  actionItem := {
    "title": "costCenterCode label is required",
    "description": "All workloads at our organization must explicitly set a costCenterCode label. [Read more](https://kubernetes.io/docs/concepts/overview/working-with-objects/labels/)",
    "remediation": "Please set `metadata.labels.costCenterCode`",
    "category": "Reliability",
    "severity": 0.5
  }
}

