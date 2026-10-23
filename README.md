# Monoceros templates

Your team's workbench templates, service descriptors and MCP servers for
[Monoceros](https://getmonoceros.build), in one repository. Every builder
clones it into `~/.monoceros/templates`, and `git pull` keeps them current.
A new workbench then starts from the team's setup instead of from whatever
each builder remembers.

In the examples below, `acme` stands for your organisation.

## Set it up for your team

Click **Use this template** at the top of this page and create a new
repository in your organisation. Make it private: your templates name
internal images, registries and hosts. Don't fork this repository instead,
because GitHub does not let a fork of a public repository be private.

Then replace the three examples with your own:

| Directory      | Holds                                                                                                            | Used by                                        |
| -------------- | ---------------------------------------------------------------------------------------------------------------- | ---------------------------------------------- |
| `workbenches/` | prepared workbench ymls ([format](https://getmonoceros.build/docs/reference/lifecycle/init/#your-own-templates)) | `monoceros init <name> --template=<file name>` |
| `services/`    | service descriptors ([format](https://getmonoceros.build/docs/services/overview/#keep-your-own-services))        | `monoceros add-service <name> <file name>`     |
| `mcp-servers/` | MCP server descriptors ([format](https://getmonoceros.build/docs/mcp-servers/overview/#keep-your-own-servers))   | `monoceros add-mcp-server <name> <file name>`  |

Monoceros reads only the `*.yml` files in these three directories. This
README, `.gitignore` and `.github/` stay out of its way.

## Use it on your machine

`git clone` needs an empty directory, so move what you already have aside:

```sh
mv ~/.monoceros/templates ~/.monoceros/templates.mine
```

```sh
git clone git@github.com:acme/monoceros-templates.git ~/.monoceros/templates
```

Bring your own files back with the `my-` prefix, so they stay out of the team
repository (see [Personal templates](#personal-templates)). A service or MCP
server also needs its `id:` changed to the new file name.

Check that Monoceros sees the team's entries. They are marked `(local)`:

```sh
monoceros list-components
```

Get the team's changes:

```sh
git -C ~/.monoceros/templates pull
```

## What a pull changes

- **A workbench template** is copied into the workbench yml by `init`. A
  change reaches the workbenches created after it, not the ones you already
  have.
- **An MCP server** is named in the workbench yml and read from its file on
  every `monoceros apply`. A change takes effect on the next `apply`.
- **A service** is copied into the workbench yml by `add-service`, with a
  `ref:` line that records its version. `apply` keeps reading that version's
  briefing. A newer version reaches an existing workbench through
  `monoceros upgrade <name>`, which merges it in and keeps the builder's own
  edits.

## Change a service

Workbenches built from a service carry its block, so a change gets a new
version. Copy the current file to `services/<id>@<version>.yml` first, then
raise `version:` in the current file and make your change. Never edit an
older version once it is merged: a workbench may still be built from it.
Keep it as long as a workbench names that version.

The check below enforces this on every pull request.

## Personal templates

A file whose name starts with `my-` (`workbenches/my-node.yml`,
`services/my-kafka.yml`) is ignored by git. It sits next to the team's files
and works the same way, but stays on your machine. A prefix rather than a
suffix, because a service id allows only lowercase letters, digits and
hyphens.

## Review changes like code

A template brings images, features with their plugins, MCP servers and
commands into everyone's workbench. Whoever can write to this repository
decides what runs there. So changes go through pull requests and review, like
code.

## The check

`.github/workflows/validate.yml` runs on every pull request and every push to
`main`. It installs Monoceros and points it at the checkout, then:

- reads every descriptor and template with `monoceros list-components`, and
  fails on a broken file or a version file Monoceros leaves out;
- renders every workbench template with `monoceros init --template`;
- on a pull request, fails when a service changed without a new version, when
  the previous version was not kept unchanged, or when an older version
  changed.

## License

[MIT-0](LICENSE): use, change and keep the content of this repository in your
own, private one, without naming where it came from.
