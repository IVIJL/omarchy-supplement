# Omarchy Supplement

Personal supplement for [Omarchy](https://github.com/basecamp/omarchy) -- additional packages, tools, and dotfiles configuration. Works on **Arch Linux** (after Omarchy) and **WSL2 Ubuntu 24.04** (standalone).

Inspired by [typecraft-dev/omarchy-supplement](https://github.com/typecraft-dev/omarchy-supplement).

## Supported platforms

| Platform | Notes |
| --- | --- |
| **Arch Linux** | Run after installing Omarchy. WezTerm, base tools available. |
| **WSL2 Ubuntu 24.04** | Standalone. `install-base.sh` replaces what Omarchy provides. WezTerm auto-skipped (install on Windows). |

The installer auto-detects the platform and filters scripts accordingly.

## What it installs

| Script | What it does | Arch | Ubuntu/WSL2 |
| --- | --- | :---: | :---: |
| `install-base.sh` | Base tools: git, zsh, bat, eza, starship, fzf (on Arch provided by Omarchy) | skip | yes |
| `install-packages.sh` | Basic tools: nano, unzip, curl, ncdu, mc, fastfetch, nala | yes | yes |
| `install-uv.sh` | [UV](https://github.com/astral-sh/uv) Python package manager (global multi-user setup) | yes | yes |
| `install-glances.sh` | [Glances](https://nicolargo.github.io/glances/) system monitor (via uv or package manager) | yes | yes |
| `install-rust.sh` | [Rust](https://www.rust-lang.org/) & Cargo via rustup | yes | yes |
| `install-atuin.sh` | [Atuin](https://atuin.sh/) shell history manager | yes | yes |
| `install-zsh-plugins.sh` | ZSH plugins: autosuggestions, syntax-highlighting, z, fzf-tab | yes | yes |
| `install-yazi.sh` | [Yazi](https://yazi-rs.github.io/) terminal file manager | yes | yes |
| `install-gdu.sh` | [GDU](https://github.com/dundee/gdu) fast disk usage analyzer (replaces ncdu) | yes | yes |
| `install-neovim.sh` | [Neovim](https://neovim.io/) + LazyVim (global shared setup with appimage) | yes | yes |
| `install-grc.sh` | [GRC](https://github.com/garabik/grc) generic colorizer | yes | yes |
| `install-wezterm.sh` | [WezTerm](https://wezfurlong.org/wezterm/) terminal emulator (Super+Enter) | yes | skip |
| `install-chezmoi.sh` | [Chezmoi](https://www.chezmoi.io/) dotfiles from [IVIJL/vlci-dotfiles](https://github.com/IVIJL/vlci-dotfiles) | yes | yes |
| `set-shell.sh` | Ensures ZSH is the default shell | yes | yes |

## Quick install

Works for both first install and re-run (auto-updates if already installed).

**WSL2 Ubuntu 24.04:**

```bash
curl -fsSL https://raw.githubusercontent.com/IVIJL/omarchy-supplement/wsl2-ubuntu/bootstrap.sh | bash
```

**Arch Linux (after merge to main):**

```bash
curl -fsSL https://raw.githubusercontent.com/IVIJL/omarchy-supplement/main/bootstrap.sh | bash
```

The bootstrap script handles everything: installs git if missing, clones (or updates) the repo, and runs the installer.

## Manual usage

```bash
# First install - WSL2 Ubuntu (wsl2-ubuntu branch)
git clone -b wsl2-ubuntu https://github.com/IVIJL/omarchy-supplement.git ~/omarchy-supplement

# First install - Arch (main branch)
git clone https://github.com/IVIJL/omarchy-supplement.git ~/omarchy-supplement

# Run
cd ~/omarchy-supplement
chmod +x *.sh
./install-all.sh all
```

### Installation modes

**Interactive mode** (default):

```bash
./install-all.sh
# Shows numbered list, select scripts by number
# Enter = install all
```

**Install all** (no interaction):

```bash
./install-all.sh all
# Installs everything without prompts (useful for automation)
```

**Select by name**:

```bash
./install-all.sh uv rust chezmoi
# Installs only install-uv.sh, install-rust.sh, install-chezmoi.sh
```

**Exclude by name**:

```bash
./install-all.sh !uv !rust
# Installs all except install-uv.sh and install-rust.sh
```

**Note**: Cannot mix positive and negative selection (e.g., `uv !rust` will error).

### Run individual scripts

You can also run scripts directly:

```bash
./install-rust.sh
./install-atuin.sh
```

### UV note

`install-uv.sh` requires sudo for global installation:

```bash
sudo ./install-uv.sh
```

## WSL2 Ubuntu 24.04 quick start

```bash
# 1. Install (or update) everything
curl -fsSL https://raw.githubusercontent.com/IVIJL/omarchy-supplement/wsl2-ubuntu/bootstrap.sh | bash

# 2. Restart your shell
exec zsh
```

WezTerm is automatically skipped on WSL2 -- install it on the Windows host instead. Nerd Fonts should also be installed on Windows for proper terminal rendering.

## Migrating existing chezmoi dotfiles to GitHub

If you already use chezmoi on another machine (e.g. work servers pulling from GitLab), here's how to push those dotfiles to `IVIJL/vlci-dotfiles` on GitHub:

```bash
# 1. Go into your chezmoi source directory (it's a normal git repo)
chezmoi cd
# or: cd ~/.local/share/chezmoi

# 2. Check current remote (probably points to GitLab)
git remote -v

# 3. Add GitHub as a new remote (or replace the old one)
#    Option A: Add as second remote (keep GitLab too)
git remote add github https://github.com/IVIJL/vlci-dotfiles.git

#    Option B: Replace the old remote entirely
#    git remote set-url origin https://github.com/IVIJL/vlci-dotfiles.git

# 4. Push everything to GitHub
git push github main
#    (or: git push -u origin main  if you used Option B)

# 5. Done! Your dotfiles are now on GitHub.
```

After that, on any new machine you just run `./install-chezmoi.sh` and it pulls from GitHub automatically (no SSH key needed -- it's a public repo via HTTPS).

To keep using chezmoi day-to-day with push access:

```bash
# After making dotfile changes, commit and push
chezmoi cd
git add -A && git commit -m "update dotfiles"
git push
```

## License

MIT
