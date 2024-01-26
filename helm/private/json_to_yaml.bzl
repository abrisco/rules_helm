"""Rules and helper functions for converting json to yaml."""

def json_to_yaml(ctx, name, json_content):
    """Render a json file to a yaml file.

    Args:
        ctx: The context of the rule.
        name: The name of the rule.
        json_content: The json content to convert to yaml.
    Returns:
        The yaml file.
    """
    yaml_file = ctx.actions.declare_file("{}.yaml".format(
        name,
    ))
    json_file = ctx.actions.declare_file("{}.json".format(
        name,
    ))
    ctx.actions.write(
        output = json_file,
        content = json_content,
    )
    args = ctx.actions.args()
    args.add("-input", json_file)
    args.add("-output", yaml_file)
    ctx.actions.run(
        executable = ctx.executable._json_to_yaml,
        mnemonic = "HelmPackageJsonToYaml",
        arguments = [args],
        inputs = [json_file],
        outputs = [yaml_file],
    )

    return yaml_file
