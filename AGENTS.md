# Agent Notes

- Keep the menu backed by `NSStatusItem`. SwiftUI's `MenuBarExtra` cannot be opened programmatically, but the global shortcut must open the same menu as clicking the status icon.
- Open the SwiftUI Settings scene through `SettingsLink`. The native status-menu item forwards to the SwiftUI-generated Settings command so it retains standard AppKit menu behavior.
- Keep semantic-release isolated in `release.yml`. Artifact building belongs in `publish.yml`, triggered by `release.published`.
- Releases must use `SEMANTIC_RELEASE_TOKEN`, not `GITHUB_TOKEN`, because events created by `GITHUB_TOKEN` do not trigger the downstream publish workflow.
- Node release tools are intentionally run through pinned `npx` packages. Do not add a local npm project solely for CI tooling.
- Published macOS artifacts are intentionally unsigned and unnotarized.
- Follow the [Conventional Commits](https://www.conventionalcommits.org/) specification for commit messages.
- Use `.github/pull_request_template.md` for every pull request and complete each section before creating or updating it.
- Never create or update a pull request unless the user explicitly requests it.
