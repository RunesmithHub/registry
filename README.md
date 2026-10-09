# Runesmith Hub registry

The registry of the [Runesmith Plugin Hub](https://hub.runesmith.dev): every publisher, plugin and published version, the hub's policies,
and the automation that builds plugins and publishes the hub's signed index. Runesmith and the website read the index this repository
publishes; nothing here needs to be downloaded by hand.

## Register a plugin

Follow the [publishing guide](https://hub.runesmith.dev/publish). Its registration form writes your publisher record and your plugin's
registration; you open one pull request with both, a check runs on it, and an administrator merges it.

## Release a version

Tag the commit, `v` followed by the version in your `plugin.json`, and create a GitHub release from the tag. Within the hour the hub
builds it, checks it and opens a tracking issue for it in this repository, where every step reports. Maintainers can open a
**Publish now** issue to start sooner.

Maintainers yank versions, deprecate plugins, change maintainers and ask for verification through the
[issue forms](https://github.com/RunesmithHub/registry/issues/new/choose).

## Report a problem

- A security problem or a malicious plugin: use [private vulnerability reporting](https://github.com/RunesmithHub/registry/security/advisories/new),
  never a public issue. See [SECURITY.md](SECURITY.md).
- A plugin that breaks Runesmith, or a policy breach: open an issue with the matching form.
- A moderation decision you disagree with: open an **Appeal** issue.

The rules plugins follow are in [policy/](policy/).

## The index

Runesmith and the website read the signed index from [GitHub Pages](https://runesmithhub.github.io/registry/). The hub's workflows build
it on the `index` branch, which nobody edits by hand; every push to that branch deploys it.
