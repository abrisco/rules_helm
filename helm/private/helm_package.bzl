"""Helm rules"""

load("//helm:providers.bzl", "HelmPackageInfo")
load("//helm/private:helm_utils.bzl", "is_stamping_enabled")

def _render_json_to_yaml(ctx, name, inline_content):
    target_file = ctx.actions.declare_file("{}/{}.yaml".format(
        name,
        ctx.label.name,
    ))
    content_json = ctx.actions.declare_file("{}/.{}.json".format(
        name,
        ctx.label.name,
    ))
    ctx.actions.write(
        output = content_json,
        content = inline_content,
    )
    args = ctx.actions.args()
    args.add("-input", content_json)
    args.add("-output", target_file)
    ctx.actions.run(
        executable = ctx.executable._json_to_yaml,
        mnemonic = "HelmPackageJsonToYaml",
        arguments = [args],
        inputs = [content_json],
        outputs = [target_file],
    )

    return target_file

def _helm_package_impl(ctx):
    if ctx.attr.values and ctx.attr.values_json:
        fail("helm_package rules cannot use both `values` and `values_json` attributes. Update {} to use one.".format(
            ctx.label,
        ))

    if ctx.attr.chart and ctx.attr.chart_json:
        fail("helm_package rules cannot use both `values` and `values_json` attributes. Update {} to use one.".format(
            ctx.label,
        ))

    if ctx.attr.values:
        values_yaml = ctx.file.values
    elif ctx.attr.values_json:
        values_yaml = _render_json_to_yaml(ctx, "values", ctx.attr.values_json)
    else:
        fail("helm_package rules requires either `values` or `values_json` attributes. Update {} to use one.".format(
            ctx.label,
        ))

    if ctx.attr.chart:
        chart_yaml = ctx.file.chart
    elif ctx.attr.chart_json:
        chart_yaml = _render_json_to_yaml(ctx, "Chart", ctx.attr.chart_json)
    else:
        fail("helm_package rules requires either `chart` or `chart_json` attributes. Update {} to use one.".format(
            ctx.label,
        ))

    args = ctx.actions.args()

    output = ctx.actions.declare_file(ctx.label.name + ".tgz")
    metadata_output = ctx.actions.declare_file(ctx.label.name + ".metadata.json")
    args.add("-output", output)
    args.add("-metadata_output", metadata_output)

    toolchain = ctx.toolchains[Label("//helm:toolchain_type")]
    args.add("-helm", toolchain.helm)

    args.add("-chart", chart_yaml)
    args.add("-values", values_yaml)

    templates_manifest = ctx.actions.declare_file("{}/templates_manifest.json".format(ctx.label.name))
    ctx.actions.write(
        output = templates_manifest,
        content = json.encode_indent({file.path: file.short_path for file in ctx.files.templates}, indent = " " * 4),
    )
    args.add("-templates_manifest", templates_manifest)

    deps = []
    if ctx.attr.deps:
        deps.extend([dep[HelmPackageInfo].chart for dep in ctx.attr.deps])
        deps_manifest = ctx.actions.declare_file("{}/deps_manifest.json".format(ctx.label.name))
        ctx.actions.write(
            output = deps_manifest,
            content = json.encode_indent([dep.path for dep in deps], indent = " " * 4),
        )
        args.add("-deps_manifest", deps_manifest)
        deps.append(deps_manifest)

    # Create documents for each image the package depends on
    image_inputs = []
    if ctx.attr.oci_images:
        single_image_manifests = []
        for image in ctx.attr.oci_images:
            single_image_manifest = ctx.actions.declare_file("{}/{}".format(
                ctx.label.name,
                str(image.label).strip("@").replace("/", "_").replace(":", "_") + ".oci_image_manifest",
            ))
            push_info = image[DefaultInfo]
            ctx.actions.write(
                output = single_image_manifest,
                content = json.encode_indent(
                    struct(
                        label = str(image.label),
                        paths = [manifest.path for manifest in push_info.default_runfiles.files.to_list()],
                    ),
                ),
            )
            image_inputs.extend(push_info.default_runfiles.files.to_list())
            single_image_manifests.append(single_image_manifest)

        image_manifest = ctx.actions.declare_file("{}/oci_image_manifest.json".format(ctx.label.name))
        ctx.actions.write(
            output = image_manifest,
            content = json.encode_indent([manifest.path for manifest in single_image_manifests], indent = " " * 4),
        )
        image_inputs.append(image_manifest)
        image_inputs.extend(single_image_manifests)
        args.add("-oci_image_manifest", image_manifest)
    stamps = []
    if is_stamping_enabled(ctx.attr):
        args.add("-volatile_status_file", ctx.version_file)
        args.add("-stable_status_file", ctx.info_file)
        stamps.extend([ctx.version_file, ctx.info_file])

    args.add("-workspace_name", ctx.workspace_name)

    ctx.actions.run(
        executable = ctx.executable._packager,
        outputs = [output, metadata_output],
        inputs = depset(
            ctx.files.templates + stamps + image_inputs + deps + [chart_yaml, values_yaml, templates_manifest],
        ),
        tools = depset([toolchain.helm]),
        mnemonic = "HelmPackage",
        arguments = [args],
        progress_message = "Creating Helm Package for {}".format(
            ctx.label,
        ),
    )

    return [
        DefaultInfo(
            files = depset([output]),
            runfiles = ctx.runfiles([output]),
        ),
        HelmPackageInfo(
            chart = output,
            metadata = metadata_output,
            oci_images = ctx.attr.oci_images,
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
        "chart_json": attr.string(
            doc = "A json encoded string to use as the `Chart.yaml` file of the helm chart",
        ),
        "deps": attr.label_list(
            doc = "Other helm packages this package depends on.",
            providers = [HelmPackageInfo],
        ),
        "oci_images": attr.label_list(
            doc = "[@rules_oci//oci:defs.bzl%oci_push](https://github.com/bazel-contrib/rules_oci/blob/main/docs/push.md#oci_push_rule-remote_tags) targets.",
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
            doc = "The `values.yaml` file for the current package. This attribute is mutally exclusive with `values_json`.",
            allow_single_file = ["values.yaml"],
        ),
        "values_json": attr.string(
            doc = "A json encoded string to use as the `values.yaml` file. This attribute is mutally exclusive with `values`.",
        ),
        "_json_to_yaml": attr.label(
            doc = "A tools for converting json files to yaml files.",
            cfg = "exec",
            executable = True,
            default = Label("//helm/private/json_to_yaml"),
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
        str(Label("@rules_helm//helm:toolchain_type")),
    ],
)
