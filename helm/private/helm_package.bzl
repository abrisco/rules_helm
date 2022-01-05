"""Helm rules"""

load("@io_bazel_rules_docker//container:providers.bzl", "PushInfo")
load("//helm:providers.bzl", "HelmPackageInfo")
load("//helm/private:helm_utils.bzl", "is_stamping_enabled")

def _helm_package_impl(ctx):
    args = ctx.actions.args()

    output = ctx.actions.declare_file(ctx.label.name + ".tgz")
    metadata_output = ctx.actions.declare_file(ctx.label.name + ".metadata.json")
    args.add("--output", output)
    args.add("--metadata_output", metadata_output)

    toolchain = ctx.toolchains[Label("//helm:toolchain_type")]
    args.add("--helm", toolchain.helm)

    args.add("--chart", ctx.file.chart)
    args.add("--values", ctx.file.values)

    for file in ctx.files.templates:
        args.add("--template", file)

    deps = []
    for dep in ctx.attr.deps:
        pkg_info = dep[HelmPackageInfo]
        args.add("--dep", pkg_info.chart)
        deps.append(pkg_info.chart)

    image_inputs = []
    for image in ctx.attr.images:
        image_manifest = ctx.actions.declare_file("{}/{}".format(
            ctx.label.name,
            str(image.label).strip("@").replace("/", "_").replace(":", "_") + ".image_manifest",
        ))
        push_info = image[PushInfo]
        ctx.actions.write(
            image_manifest,
            json.encode_indent(struct(
                label = str(image.label),
                registry = push_info.registry,
                repository = push_info.repository,
                digest = push_info.digest.path,
            ), indent = " " * 4),
        )
        image_inputs.extend([image_manifest, push_info.digest])
        args.add("--image_manifest", image_manifest)

    stamps = []
    if is_stamping_enabled(ctx.attr):
        args.add("--volatile_status_file", ctx.version_file)
        args.add("--stable_status_file", ctx.info_file)
        stamps.extend([ctx.version_file, ctx.info_file])

    args.add("--workspace_name", ctx.workspace_name)

    ctx.actions.run(
        executable = ctx.executable._packager,
        outputs = [output, metadata_output],
        inputs = depset(
            ctx.files.templates + stamps + image_inputs + deps + [ctx.file.chart, ctx.file.values],
        ),
        tools = depset([toolchain.helm]),
        mnemonic = "HelmPackage",
        arguments = [args],
    )

    return [
        DefaultInfo(
            files = depset([output]),
            runfiles = ctx.runfiles([output]),
        ),
        HelmPackageInfo(
            chart = output,
            metadata = metadata_output,
            images = ctx.attr.images,
        ),
    ]

helm_package = rule(
    implementation = _helm_package_impl,
    doc = "",
    attrs = {
        "chart": attr.label(
            doc = "The `Chart.yaml` file of the helm chart",
            allow_single_file = ["Chart.yaml"],
        ),
        "deps": attr.label_list(
            doc = "Other helm packages this package depends on.",
            providers = [HelmPackageInfo],
        ),
        "images": attr.label_list(
            doc = "[@rules_docker//container:push.bzl%container_push](https://github.com/bazelbuild/rules_docker/blob/v0.22.0/docs/container.md#container_push) targets.",
            providers = [PushInfo],
        ),
        "stamp": attr.int(
            doc = """\
                Whether to encode build information into the helm actions. Possible values:

                - `stamp = 1`: Always stamp the build information into the helm actions, even in \
                [--nostamp](https://docs.bazel.build/versions/main/user-manual.html#flag--stamp) builds. \
                This setting should be avoided, since it potentially kills remote caching for the target and \
                any downstream actions that depend on it.

                - `stamp = 0`: Always replace build information by constant values. This gives good build result caching.

                - `stamp = -1`: Embedding of build information is controlled by the \
                [--[no]stamp](https://docs.bazel.build/versions/main/user-manual.html#flag--stamp) flag.

                Stamped targets are not rebuilt unless their dependencies change.
            """,
            default = -1,
            values = [1, 0, -1],
        ),
        "templates": attr.label_list(
            doc = "All templates associated with the current helm chart. E.g., the `./templates` directory",
            allow_files = True,
        ),
        "values": attr.label(
            doc = "The `values.yaml` file for the current package.",
            allow_single_file = ["values.yaml"],
        ),
        "_packager": attr.label(
            doc = "A process wrapper for producing the helm package's `tgz` file",
            cfg = "exec",
            executable = True,
            default = Label("//helm/private/packager"),
        ),
        "_stamp_flag": attr.label(
            doc = "A setting used to determine whether or not the `--stamp` flag is enabled",
            default = Label("//helm/private:stamp"),
        ),
    },
    toolchains = [
        str(Label("//helm:toolchain_type")),
    ],
)

def _helm_install_impl(ctx):
    toolchain = ctx.toolchains[Label("//helm:toolchain_type")]

    if toolchain.helm.basename.endswith(".exe"):
        installer = ctx.actions.declare_file(ctx.label.name + ".bat")
    else:
        installer = ctx.actions.declare_file(ctx.label.name + ".sh")

    install_name = ctx.attr.install_name or ctx.label.name

    pkg_info = ctx.attr.package[HelmPackageInfo]

    image_pushers = []
    image_runfiles = []
    for image in pkg_info.images:
        image_pushers.append(image[DefaultInfo].files_to_run.executable)
        image_runfiles.append(image[DefaultInfo].default_runfiles)

    ctx.actions.expand_template(
        template = ctx.file._installer,
        output = installer,
        substitutions = {
            "{chart}": pkg_info.chart.short_path,
            "{helm}": toolchain.helm.short_path,
            "{image_pushers}": "\n".join([pusher.short_path for pusher in image_pushers]),
            "{install_name}": install_name,
        },
        is_executable = True,
    )

    runfiles = ctx.runfiles([installer, toolchain.helm, pkg_info.chart] + image_pushers)
    for ir in image_runfiles:
        runfiles = runfiles.merge(ir)

    return [
        DefaultInfo(
            files = depset([installer]),
            runfiles = runfiles,
            executable = installer,
        ),
    ]

helm_install = rule(
    doc = "Produce a script for performing a helm install action",
    implementation = _helm_install_impl,
    executable = True,
    attrs = {
        "install_name": attr.string(
            doc = "",
        ),
        "package": attr.label(
            doc = "",
            providers = [HelmPackageInfo],
            mandatory = True,
        ),
        "_installer": attr.label(
            doc = "",
            allow_single_file = True,
            default = Label("//helm/private/installer:template"),
        ),
    },
    toolchains = [
        str(Label("//helm:toolchain_type")),
    ],
)

def _helm_uninstall_impl(ctx):
    toolchain = ctx.toolchains[Label("//helm:toolchain_type")]

    if toolchain.helm.basename.endswith(".exe"):
        uninstaller = ctx.actions.declare_file(ctx.label.name + ".bat")
    else:
        uninstaller = ctx.actions.declare_file(ctx.label.name + ".sh")

    install_name = ctx.attr.install_name or ctx.label.name

    ctx.actions.expand_template(
        template = ctx.file._uninstaller,
        output = uninstaller,
        substitutions = {
            "{helm}": toolchain.helm.short_path,
            "{install_name}": install_name,
        },
        is_executable = True,
    )

    return [
        DefaultInfo(
            files = depset([uninstaller]),
            runfiles = ctx.runfiles([uninstaller, toolchain.helm]),
            executable = uninstaller,
        ),
    ]

helm_uninstall = rule(
    doc = "Produce a script for performing a helm uninstall action",
    implementation = _helm_uninstall_impl,
    executable = True,
    attrs = {
        "install_name": attr.string(
            doc = "",
        ),
        "_uninstaller": attr.label(
            doc = "",
            allow_single_file = True,
            default = Label("//helm/private/uninstaller:template"),
        ),
    },
    toolchains = [
        str(Label("//helm:toolchain_type")),
    ],
)

def _helm_push_impl(ctx):
    toolchain = ctx.toolchains[Label("//helm:toolchain_type")]

    if toolchain.helm.basename.endswith(".exe"):
        pusher = ctx.actions.declare_file(ctx.label.name + ".bat")
    else:
        pusher = ctx.actions.declare_file(ctx.label.name + ".sh")

    pkg_info = ctx.attr.package[HelmPackageInfo]

    image_pushers = []
    image_runfiles = []
    for image in pkg_info.images:
        image_pushers.append(image[DefaultInfo].files_to_run.executable)
        image_runfiles.append(image[DefaultInfo].default_runfiles)

    ctx.actions.expand_template(
        template = ctx.file._pusher,
        output = pusher,
        substitutions = {
            "{image_pushers}": "\n".join([pusher.short_path for pusher in image_pushers]),
        },
        is_executable = True,
    )

    runfiles = ctx.runfiles([pusher] + image_pushers)
    for ir in image_runfiles:
        runfiles = runfiles.merge(ir)

    return [
        DefaultInfo(
            files = depset([pusher]),
            runfiles = runfiles,
            executable = pusher,
        ),
    ]

helm_push = rule(
    doc = "Produce a script for pushing all docker images used by a helm chart",
    implementation = _helm_push_impl,
    executable = True,
    attrs = {
        "package": attr.label(
            doc = "",
            providers = [HelmPackageInfo],
            mandatory = True,
        ),
        "_pusher": attr.label(
            doc = "",
            allow_single_file = True,
            default = Label("//helm/private/pusher:template"),
        ),
    },
    toolchains = [
        str(Label("//helm:toolchain_type")),
    ],
)

def _helm_lint_aspect_impl(target, ctx):
    if HelmPackageInfo not in target:
        return []

    helm_pkg_info = target[HelmPackageInfo]
    toolchain = ctx.toolchains[Label("//helm:toolchain_type")]

    output = ctx.actions.declare_file(ctx.label.name + ".helm_lint.ok")

    args = ctx.actions.args()
    args.add("--helm", toolchain.helm)
    args.add("--package", helm_pkg_info.chart)
    args.add("--output", output)

    ctx.actions.run(
        outputs = [output],
        executable = ctx.executable._linter,
        mnemonic = "HelmLintCheck",
        inputs = [helm_pkg_info.chart],
        tools = [toolchain.helm],
        arguments = [args],
    )

    return [
        OutputGroupInfo(
            helm_lint_checks = depset([output]),
        ),
    ]

helm_lint_aspect = aspect(
    doc = "An aspect for running `helm lint` on helm package targets",
    implementation = _helm_lint_aspect_impl,
    attrs = {
        "_linter": attr.label(
            doc = "",
            cfg = "exec",
            executable = True,
            default = Label("//helm/private/linter:linter"),
        ),
    },
    toolchains = [
        str(Label("//helm:toolchain_type")),
    ],
)
