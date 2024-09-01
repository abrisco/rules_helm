"""Test rules for the `with_multiple_templates` tests."""

def _copy_to_directory_impl(ctx):
    out = ctx.actions.declare_directory(ctx.label.name)

    args = ctx.actions.args()
    args.add("-output", out.path)
    args.add_all(ctx.files.srcs, format_each = "-src=%s")
    args.add_all(ctx.attr.root_paths, format_each = "-root_path=%s")

    ctx.actions.run(
        mnemonic = "CopyToDirectory",
        executable = ctx.executable._copier,
        inputs = ctx.files.srcs,
        outputs = [out],
        arguments = [args],
    )

    return [DefaultInfo(
        files = depset([out]),
        runfiles = ctx.runfiles([out]),
    )]

copy_to_directory = rule(
    doc = "Copy files into a directory.",
    implementation = _copy_to_directory_impl,
    attrs = {
        "root_paths": attr.string_list(
            doc = "Prefixes to strip from files when copying.",
        ),
        "srcs": attr.label_list(
            doc = "Files to copy.",
            allow_files = True,
            mandatory = True,
        ),
        "_copier": attr.label(
            cfg = "exec",
            executable = True,
            default = Label("//tests/with_multiple_templates:copy_to_dir"),
        ),
    },
)
