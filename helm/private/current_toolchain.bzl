"""This module implements an alias rule to the resolved helm toolchain.
"""

DOC = """\
Exposes a concrete toolchain which is the result of Bazel resolving the
toolchain for the execution or target platform.
Workaround for https://github.com/bazelbuild/bazel/issues/14009
"""

# Forward all the providers
def _current_helm_toolchain_impl(ctx):
    toolchain_info = ctx.toolchains["@rules_helm//helm:toolchain_type"]
    return [
        toolchain_info,
        toolchain_info.default_info,
        toolchain_info.template_variables,
    ]

# Copied from java_toolchain_alias
# https://cs.opensource.google/bazel/bazel/+/master:tools/jdk/java_toolchain_alias.bzl
current_helm_toolchain = rule(
    implementation = _current_helm_toolchain_impl,
    toolchains = ["@rules_helm//helm:toolchain_type"],
    incompatible_use_toolchain_transition = True,
    doc = DOC,
)
