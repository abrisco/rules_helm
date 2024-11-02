"""Helm toolchain rules"""

load(
    "//helm/private:helm_toolchain.bzl",
    _helm_toolchain = "helm_toolchain",
)

helm_toolchain = _helm_toolchain
