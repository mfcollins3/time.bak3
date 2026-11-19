# Apple Applications

This directory contains the source code for the Naked Time applications that run
on Apple devices (macOS, iOS, watchOS).

1. [Prerequisites](#prerequisites)
1. [Layout](#layout)
1. [Tuist](#tuist)

## Prerequisites

* [mise-en-place](https://mise.jdx.dev/)
* [Tuist](https://tuist.dev) (**Installed using `mise`**)
* [Xcode 27.2](https://developer.apple.com/xcode)

Tuist should be installed automatically for developers running on Apple macOS
using the `setup.sh` or `Setup-Time.ps1` scripts that were executed after
cloning the Git repository.

## Layout

```plain
src/apple/                              Root directory
|-- Projects/                           Source code for the application and framework projects
|   |-- App/                            Source code for the Naked Time application
|   |   |-- Resources/                  Asset catalogs, string catalogs, and other assets used by the Naked Time application
|   |   |   |-- Assets.xcassets/        Asset catalog that contains the application icon and other resources for the Naked Time application
|   |   |   |-- InfoPlist.xcstrings     String catalog containing localized strings for metadata in the Info.plist file for the Naked Time application
|   |   |-- Sources/                    Source code for the Naked Time application
|   |   |   |-- MainScene.swift         Implements the main scene for the Naked Time application
|   |   |   |-- MainView.swift          Implements the primary user experience for the Naked Time application
|   |   |   |-- TimeApp.swift           Implements the Naked Time application
|   |   Project.swift                   Tuist project manifest for the Naked Time application
|-- Tuist/                              Manages and stores Swift package dependencies used by the Naked Time application
|   |-- Package.swift                   Swift package manifest that specifies the Swift package dependencies needed to build and run the Naked Time application
|-- .gitignore                          Excludes Apple-specific files from the Git repository
|-- README.md                           Documentation about the Apple applications and frameworks
|-- Tuist.swift                         Configures how Tuist generates project files and source code
|-- Workspace.swift                     Manifest file used by Tuist to generate the Xcode workspace
```

## Tuist

Naked Time uses [Tuist](https://tuist.dev/en/docs/guides/features/projects) for
managing and generating the Xcode workspace and project configurations. Tuist
allows us to control the structure and configuration of the applications, Swift
packages, and frameworks using Swift code. Tuist will then use these manifest
files to generate the Xcode workspace, projects, and other source code needed to
develop, build, and run the Naked Time applications on Apple devices.

### Project manifests

Tuist uses
[Swift manifests](https://tuist.dev/en/docs/guides/features/projects/manifests)
to configure and generate the project files. The following manifests are
defined:

* [Xcode workspace](Workspace.swift)
* [Naked Time application](Projects/App/Project.swift)

Xcode is used to edit the manifest files. In a terminal, navigate to the
`src/apple` folder in the repository and run:

```bash
tuist edit
```

This command will open an Xcode window that will display the manifests to be
edited.

### Dependencies

Tuist uses Swift Package Manager to
[manage dependencies](https://tuist.dev/en/docs/guides/features/projects/dependencies)
for the application. Dependencies are added to the
[`Tuist/Package.swift`](Tuist/Package.swift) manifest file. Tuist will download
and build the dependencies and link them into the application code.

To download and build dependencies, open a terminal, navigate to the
`src/apple` directory, and run:

```bash
tuist install
```

### Generating Xcode projects and source code

To regenerate the Xcode projects after editing the manifests or adding,
removing, or updating dependencies, open a terminal and navigate to the
`src/apple` folder and run:

```bash
tuist generate
```

This command will regenerate the Xcode workspace, project files, and other
source code used by the Naked Time source code.
