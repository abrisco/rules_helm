"""# rules_helm

Bazel rules for producing [helm charts][helm]

[helm]: https://helm.sh/

## Setup WORKSPACE

```starlark
load("@bazel_tools//tools/build_defs/repo:http.bzl", "http_archive")

# See releases for urls and checksums
http_archive(
    name = "rules_helm",
    sha256 = "{sha256}",
    urls = ["https://github.com/abrisco/rules_helm/releases/download/{version}/rules_helm-v{version}.tar.gz"],
)

load("@rules_helm//helm:repositories.bzl", "helm_register_toolchains", "rules_helm_dependencies")

rules_helm_dependencies()

helm_register_toolchains()

load("@rules_helm//helm:repositories_transitive.bzl", "rules_helm_transitive_dependencies")

rules_helm_transitive_dependencies()
```

## Setup MODULE

```starlark
bazel_dep(name = "rules_helm", version = "{version}")
```

## Rules

- [helm_chart](#helm_chart)
- [helm_import_repository](#helm_import_repository)
- [helm_import](#helm_import)
- [helm_install](#helm_install)
- [helm_lint_aspect](#helm_lint_aspect)
- [helm_lint_test](#helm_lint_test)
- [helm_package](#helm_package)
- [helm_push](#helm_push)
- [helm_register_toolchains](#helm_register_toolchains)
- [helm_reinstall](#helm_reinstall)
- [helm_toolchain](#helm_toolchain)
- [helm_uninstall](#helm_uninstall)
- [rules_helm_dependencies](#rules_helm_dependencies)
- [chart_content](#chart_content)

"""

load(
    "//helm/private:helm_import.bzl",
    _helm_import = "helm_import",
    _helm_import_repository = "helm_import_repository",
)
load(
    "//helm/private:helm_install.bzl",
    _helm_install = "helm_install",
    _helm_push = "helm_push",
    _helm_reinstall = "helm_reinstall",
    _helm_uninstall = "helm_uninstall",
)
load(
    "//helm/private:helm_registry.bzl",
    _helm_push_registry = "helm_push_registry",
)
load(
    "//helm/private:helm_lint.bzl",
    _helm_lint_aspect = "helm_lint_aspect",
    _helm_lint_test = "helm_lint_test",
)
load(
    "//helm/private:helm_package.bzl",
    _helm_package = "helm_package",
)
load(
    ":helm.bzl",
    _chart_content = "chart_content",
    _helm_chart = "helm_chart",
)
load(
    ":providers.bzl",
    _HelmPackageInfo = "HelmPackageInfo",
)
load(
    ":repositories.bzl",
    _helm_register_toolchains = "helm_register_toolchains",
    _rules_helm_dependencies = "rules_helm_dependencies",
)
load(
    ":toolchain.bzl",
    _helm_toolchain = "helm_toolchain",
)

helm_chart = _helm_chart
helm_import = _helm_import
helm_import_repository = _helm_import_repository
helm_install = _helm_install
helm_push_registry = _helm_push_registry
helm_lint_aspect = _helm_lint_aspect
helm_lint_test = _helm_lint_test
helm_package = _helm_package
helm_push = _helm_push
helm_register_toolchains = _helm_register_toolchains
helm_reinstall = _helm_reinstall
helm_toolchain = _helm_toolchain
helm_uninstall = _helm_uninstall
HelmPackageInfo = _HelmPackageInfo
rules_helm_dependencies = _rules_helm_dependencies
chart_content = _chart_content
