# AnyIpsum

> macOS menu bar application that lets you select a [lorem ipsum](https://en.wikipedia.org/wiki/Lorem_ipsum) variation and copy it to the pasteboard.

![Screenshot of the AnyIpsum application](media/screenshot.png)

Variations are stored in `Ipsum.plist`, and will be read upon application launch.

## Prerequisites

macOS Sonoma 14.0 or later

## Install

Download the latest disk image from [here](https://github.com/jlowgren/AnyIpsum/releases/latest).

## Usage

Click the menu bar icon, or press <kbd>CTRL</kbd><kbd>CMD</kbd><kbd>A</kbd>, and pick a variation. A paragraph will be copied to the pasteboard. The global shortcut can be changed in Settings.

Example output:

> Candy roll topping chocolate cake bear bar gummies bonbon sweet cupcake snaps fruitcake. Fruitcake sweet gummies liquorice pie sweet cake plum pie marzipan sweet caramels chups biscuit sweet. Dessert chocolate plum cake cupcake candy candy candy marzipan roll pudding jelly fruitcake. Cake snaps roll candy donut gummies pie sesame sugar cake cotton claw tootsie. Chocolate oat powder sesame gummies pudding powder pudding gummies caramels jellyo roll. Candy candy powder cheesecake candy pie. Bear marzipan oat gummies pie chocolate fruitcake wafer candy cupcake caramels roll cake sugar chocolate. Pudding caramels cake topping cake pie cake tootsie tart sugar apple snaps claw.

## Development

Commit messages follow [Conventional Commits](https://www.conventionalcommits.org/). Pull requests and pushes are checked with commitlint.

The `Build` workflow tests pull requests and pushes to `main`. After a successful build on `main`, the isolated `Release` workflow runs semantic-release. Release-worthy commits generate release notes, attach a generated `CHANGELOG.md` to the GitHub release, and create a version tag without pushing a release commit to protected `main`. Publishing that release triggers the separate `Publish Release` workflow, which builds and attaches unsigned universal macOS ZIP and DMG artifacts. Use `feat:` for a minor release, `fix:` for a patch release, and a breaking-change footer for a major release.

Publishing adds SHA-256 checksums and generates GitHub artifact provenance attestations. The app is not code-signed or notarized, so users may need to explicitly allow it through macOS Gatekeeper.

The release workflow can also be started manually with `dry_run` enabled. A dry run reports semantic-release's proposed version and release notes without tagging or publishing anything.

Add a repository secret named `SEMANTIC_RELEASE_TOKEN` containing a fine-grained personal access token with repository Contents read/write permission. A dedicated token is required because releases created with the default `GITHUB_TOKEN` do not trigger the downstream `release.published` workflow.

## License

MIT
