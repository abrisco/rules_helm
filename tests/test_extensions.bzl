"""Bzlmod test extensions"""

load("//tests:test_deps.bzl", "helm_test_deps")

def _helm_test_impl(_ctx):
    helm_test_deps()

helm_test = module_extension(
    implementation = _helm_test_impl,
)
