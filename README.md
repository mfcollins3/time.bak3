# Naked Time

1. [About Naked Time](#about-naked-time)
1. [Project layout](#project-layout)
1. [Getting started](#getting-started)
1. [Technical documentation](#technical-documentation)
1. [License](#license)

## About Naked Time

Naked Time is a time management tool for use by individuals, small teams, or
large enterprises. Naked Time helps people to plan their available time towards
completing important activities and analyze and improve their use of time. By
using Naked Time, users can better understand how much of their time is being
spent on valuable activities instead of activities that are not contributing to
value.

Naked Time utilizes the
[Pomodoro Technique](https://en.wikipedia.org/wiki/Pomodoro_Technique) for time
management. The Pomodoro Technique breaks up work into blocks of 25 minutes of
hyperfocused work time followed by a 5 minute mental break. The Pomodoro
Technique helps users to focus on completing the immediate task ahead of them,
and time boxing work combined with a break helps prevent and physical fatigue
and burnout.

## Project layout

```plain
(repo-root)/                        Root directory
|-- .claude/                        Local configuration for Claude Code
|   |-- settings.json               Project-specific settings for Claude Code
|-- .github/                        GitHub assets and configuration files
|   |-- copilot/                    GitHub Copilot assets and configuration settings
|   |   |-- settings.json           Project-specific settings for GitHub Copilot
|-- docs/                           Technical documentation for Naked Time
|   |-- adrs/                       Architectural Decision Records (ADRs) that capture important technical decisions that affect development of the Naked Time product
|   |   |-- README.md               Index of the Architectural Decision Records (ADRs)
|   |-- README.md                   Index for all of the technical documentation for Naked Time
|-- src/                            Source code for the Naked Time product
|   |-- apphost/                    Source code for the Aspire AppHost
|   |   |-- .node-version           Current version of Node.js. Used by fnm to install and activate the correct version of Node.js for Naked Time.
|   |   |-- apphost.mts             Aspire AppHost orchestrator configuration
|   |   |-- aspire.config.json      Configuration file for the Aspire AppHost
|   |   |-- eslint.config.mjs       Configuration settings for ESLint for the Aspire AppHost
|   |   |-- package.json            Node.js package manifest for the Aspire AppHost
|   |   |-- pnpm-lock.yaml          Dependency metadata managed by pnpm for the Aspire AppHost
|   |   |-- pnpm-workspace.yaml     Additional settings for pnpm
|   |   |-- README.md               Documentation for the Aspire AppHost
|   |   |-- tsconfig.apphost.yaml   TypeScript compiler settings for the Aspire AppHost
|   |-- README.md                   Index for the source code
|-- .gitattributes                  Settings that control how Git treats repository files
|-- .gitignore                      List of files or directories that should be excluded from the Git repository
|-- .mise.toml                      Lists mise packages and versions used by Naked Time and configures what tools mise manages for Naked Time
|-- .node-version                   Current version of Node.js. Used by fnm to install and activate the correct version of Node.js for Naked Time.
|-- LICENSE.md                      The license agreement for the Naked Time product and source code
|-- README.md                       This document; describes the Naked Time product and provides instructions for working with Naked Time and the source code locally
|-- Run-Time.ps1                    Builds and runs Naked Time locally on Microsoft Windows or for developers who prefer PowerShell on Apple macOS and Linux
|-- run.sh                          Builds and runs Naked Time locally on Apple macOS or Linux
|-- Setup-Time.ps1                  One-time initialization script for Microsoft Windows developers or developers that prefer PowerShell on Apple macOS or Linux
|-- setup.sh                        One-time initialization script for Apple macOS or Linux developers
|-- time.code-workspace             Visual Studio Code workspace for the Naked Time product
```

## Getting started

This section provides instructions on how to clone the Git repository from
[GitHub](https://github.com) and then build and run the Naked Time product
locally on a development computer.

### Prerequisites

* [Git](https://git-scm.com)
* [GitHub CLI](https://cli.github.com)
* [pnpm](https://pnpm.io/)
* [fnm](https://github.com/Schniz/fnm)
* [Aspire CLI](https://aspire.dev/get-started/install-cli/)

### Cloning the Git repository

Open a terminal and navigate to the location in the file system where you want
to store the Git repository for Naked Time. Run:

```bash
gh repo clone mfcollins3/time time/main
```

This command will clone the
[`mfcollins3/time`](https://github.com/mfcollins3/time) repository from GitHub
into the `time/main` subdirectory. By default, the `gh repo clone` command will
check out the `main` branch.

### Set up the project workspace

Naked Time requires additional tools and libraries be downloaded and installed
in the repository to build the product. In addition, some source code and tool
files need to be generated to build the product. The steps required to prepare
the new clone for building and running Naked Time has been automated using the
`setup.sh` or `Setup-Time.ps1` program.

In the terminal, run:

* **Apple macOS or Linux:**

  ```bash
  cd time/main
  ./setup.sh
  ```

* **Microsoft Windows or PowerShell developers:**

  ```powershell
  cd time\main
  &".\Setup-Time.ps1"
  ```

### Running Naked Time

Naked Time uses [Aspire](https://aspire.dev) to support local development and
execution for testing and debugging. Aspire implements an application
orchestrator that will run the application components and services and link them
together on the local machine.

In a terminal, run the following command from the root directory of the Git
repository:

* **Apple macOS or Linux:**

  ```bash
  ./run.sh
  ```

* Microsoft Windows or Powershell developers:

  ```powershell
  &".\Run-Time.ps1"
  ```

## Technical documentation

For technical documentation including architecture documentation, decisions,
provisioning and deployment instructions, please review the
[Technical Documentation index](docs/README.md).

## License

Please be sure to review the [license](LICENSE.md). Naked Time is being released
under a _source available_ license and not an open source license. Naked Time is
a commercial product that requires users to have a valid license to use the
product. Licensed users may also use Naked Time source code to customize the
product for their own use or use the source code to build integrations and
extensions for the Naked Time product.
