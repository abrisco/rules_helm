"""# helm_package rule."""

load(
    "//helm/private:helm_package.bzl",
    _helm_package = "helm_package",
)

helm_package = _helm_package
