"""# helm_chart rule."""

load(
    "//helm/private:helm.bzl",
    _helm_chart = "helm_chart",
)

helm_chart = _helm_chart
