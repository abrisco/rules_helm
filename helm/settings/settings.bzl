"""# Helm settings

Definitions for all `@rules_helm//helm` settings
"""

load(
    "@bazel_skylib//rules:common_settings.bzl",
    "bool_flag",
)

def lint_default_strict():
    """A flag to control whether or not `helm_lint_*` rules default `-strict` to `True`
    """
    bool_flag(
        name = "lint_default_strict",
        build_setting_default = True,
    )
