# Monoceros templates

Your team's workbench templates, service descriptors and MCP servers for
[Monoceros](https://getmonoceros.build), in one repository. Every builder
clones it into `~/.monoceros/templates`, and `git pull` keeps them current.
A new workbench then starts from the team's setup instead of from whatever
each builder remembers.

## Set it up for your team

Click **Use this template** at the top of this page and create a new
repository in your organisation. Make it private: your templates name
internal images, registries and hosts. Don't fork this repository instead,
because GitHub does not let a fork of a public repository be private.

Then replace the three examples (`standard`, `rabbitmq`, `deepwiki`) with your
own. Keep `workbenches/template-authoring.yml`: it is the workbench an agent
works on this repository in ([below](#let-an-agent-work-on-it)).

| Directory      | Holds                                                                                                         | Used by                                        |
| -------------- | ------------------------------------------------------------------------------------------------------------- | ---------------------------------------------- |
| `workbenches/` | prepared workbench ymls ([format](https://getmonoceros.build/docs/reference/templates/workbench-template/))   | `monoceros init <name> --template=<file name>` |
| `services/`    | service descriptors ([format](https://getmonoceros.build/docs/reference/templates/service-descriptor/))       | `monoceros add-service <name> <file name>`     |
| `mcp-servers/` | MCP server descriptors ([format](https://getmonoceros.build/docs/reference/templates/mcp-server-descriptor/)) | `monoceros add-mcp-server <name> <file name>`  |

Monoceros reads only the `*.yml` files in these three directories. This
README, `.gitignore` and `.github/` stay out of its way.

A workbench that already works becomes a template with
`monoceros create-template <workbench> <template> --description "…"`.

## Use it on your machine

Monoceros reads these files from `~/.monoceros/templates`. Turn that folder
into a copy of your team's repository. Files you already keep there stay where
they are, and without a folder yet, the same steps create it.

Make the folder a Git repository:

```sh
git init -b main ~/.monoceros/templates
```

Connect it to your team's repository:

```sh
git -C ~/.monoceros/templates remote add origin [HTTPS URL of your team repository]
```

Get the repository's files:

```sh
git -C ~/.monoceros/templates pull --set-upstream origin main
```

If one of your files has the same name as a file in the repository, the pull
stops and names it. Rename your file and run the pull again, then keep the one
you want. A service or MCP server must end up under its old name, because your
workbenches name it.

The files you already had usually belong in the team repository: commit them
there. One that should stay yours keeps its name, so the workbenches that use
it still find it, and goes into `.gitignore`.

Check that Monoceros sees the team's entries. They are marked `(local)`:

```sh
monoceros list-components
```

Get the team's changes:

```sh
git -C ~/.monoceros/templates pull
```

### On Windows

Monoceros keeps its home in its own WSL distribution, and
`%USERPROFILE%\.monoceros` links to it. PowerShell does not expand `~` for
`git`, so a `~` path ends up as a folder literally named `~` in the current
directory. Use `$env:USERPROFILE` in PowerShell instead.

Make the folder a Git repository:

```powershell
git init -b main "$env:USERPROFILE\.monoceros\templates"
```

Git for Windows refuses to work in it until you allow it, because the folder
belongs to the WSL user. Allow this one folder, once:

```powershell
git config --global --add safe.directory '%(prefix)///wsl.localhost/monoceros/home/ubuntu/.monoceros/templates'
```

Connect it to your team's repository:

```powershell
git -C "$env:USERPROFILE\.monoceros\templates" remote add origin [HTTPS URL of your team repository]
```

Get the repository's files:

```powershell
git -C "$env:USERPROFILE\.monoceros\templates" pull --set-upstream origin main
```

Get the team's changes:

```powershell
git -C "$env:USERPROFILE\.monoceros\templates" pull
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
version. Start it before you edit:

```sh
monoceros create-version rabbitmq
```

That keeps the current file as `services/rabbitmq@<version>.yml` and raises
`version:` in `services/rabbitmq.yml`; make your change there. Never edit an
older version once it is in the repository: a workbench may still be built from it. Keep
it as long as a workbench names that version.

The check below enforces this on every push and pull request.

## Let an agent work on it

An agent works in a workbench, not on your machine. The template
`template-authoring` sets one up for this repository: Claude Code, and the
Monoceros docs MCP server, where the agent looks up the formats. Create it
with your team's repository:

```sh
monoceros init team-templates --template=template-authoring --with-repos=[HTTPS URL of your team repository]
```

Fill in `GITHUB_API_TOKEN` in `team-templates.env`, so the agent can push, then
build it with `monoceros apply team-templates`. The agent pushes its change,
the check tests it, and you get it on your machine with `git pull`. The
[guide](https://getmonoceros.build/docs/guides/templates/#create-a-template-with-an-agent)
walks through it.

## Personal templates

A file whose name starts with `my-` (`workbenches/my-node.yml`,
`services/my-kafka.yml`) is ignored by git. It sits next to the team's files
and works the same way, but stays on your machine. A prefix rather than a
suffix, because a service id allows only lowercase letters, digits and
hyphens.

## Review changes like code

A template brings images, features with their plugins, MCP servers and
commands into everyone's workbench. Whoever can write to this repository
decides what runs there. So review changes like code, in whatever way your
team works.

## The check

`.github/workflows/validate.yml` runs on every push, to any branch, and on
every pull request. It installs Monoceros and points it at the checkout, then:

- reads every descriptor and template with `monoceros list-components`, and
  fails on a broken file or a version file Monoceros leaves out;
- renders every workbench template with `monoceros init --template`;
- fails when a service changed without a new version, when the previous
  version was not kept unchanged, or when an older version changed. A push
  is compared with the state before it, a new branch and a pull request with
  their base.

## License

[MIT-0](LICENSE): use, change and keep the content of this repository in your
own, private one, without naming where it came from.
