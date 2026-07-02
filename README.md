# geul

geul is a macOS Markdown viewer for CLI-first developers.

## Install

### Homebrew

geul is distributed through the `iianjun/geul` Homebrew Cask tap. There is no Homebrew formula, so use `--cask`:

```bash
brew tap iianjun/geul
brew install --cask geul
```

If Homebrew reports `Refusing to load cask ... from untrusted tap`, trust the tap once and rerun the cask install:

```bash
brew trust iianjun/geul
brew install --cask geul
```

`brew install geul` is not supported. If Homebrew reports that no formula is available, rerun the install command with `--cask`.

### Direct Download

Download the latest DMG from GitHub Releases:

```text
https://github.com/iianjun/geul/releases/latest
```

## Usage

Open a Markdown file:

```bash
ge README.md
```

Open the terminal finder:

```bash
ge
```

`geul` is also installed as a fallback CLI command by the cask.

## Update

Homebrew users:

```bash
brew upgrade --cask geul
```

Direct download users should install the latest DMG from GitHub Releases.

## Requirements

- macOS 14 or later
