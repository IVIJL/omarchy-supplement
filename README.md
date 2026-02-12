# Omarchy Supplement

Personal supplement for [Omarchy](https://github.com/basecamp/omarchy) -- additional packages, tools, and dotfiles configuration. Meant to be run **after** installing Omarchy.

Inspired by [typecraft-dev/omarchy-supplement](https://github.com/typecraft-dev/omarchy-supplement).

## What it installs

| Script                   | What it does                                                                                                   |
| ------------------------ | -------------------------------------------------------------------------------------------------------------- |
| `install-packages.sh`    | Basic tools: nano, unzip, curl, ncdu, mc, fastfetch                                                            |
| `install-uv.sh`          | [UV](https://github.com/astral-sh/uv) Python package manager (global multi-user setup)                         |
| `install-glances.sh`     | [Glances](https://nicolargo.github.io/glances/) system monitor (via uv or yay)                                 |
| `install-rust.sh`        | [Rust](https://www.rust-lang.org/) & Cargo via rustup                                                          |
| `install-atuin.sh`       | [Atuin](https://atuin.sh/) shell history manager                                                               |
| `install-zsh-plugins.sh` | ZSH plugins: autosuggestions, syntax-highlighting, z, fzf-tab                                                  |
| `install-yazi.sh`        | [Yazi](https://yazi-rs.github.io/) terminal file manager                                                       |
| `install-wezterm.sh`     | [WezTerm](https://wezfurlong.org/wezterm/) terminal emulator + sets as primary terminal (Super+Enter)          |
| `install-chezmoi.sh`     | [Chezmoi](https://www.chezmoi.io/) dotfiles from [IVIJL/vlci-dotfiles](https://github.com/IVIJL/vlci-dotfiles) |
| `set-shell.sh`           | Ensures ZSH is the default shell                                                                               |

## What Omarchy already provides (not reinstalled)

- Neovim, Zsh, Starship, Eza, Fzf, Nerd Fonts, curl, git, unzip

## Usage

```bash
git clone https://github.com/IVIJL/omarchy-supplement.git ~/omarchy-supplement
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

After that, on any new Omarchy machine you just run `./install-chezmoi.sh` and it pulls from GitHub automatically (no SSH key needed -- it's a public repo via HTTPS).

To keep using chezmoi day-to-day on the Omarchy machine with push access:

```bash
# After making dotfile changes, commit and push
chezmoi cd
git add -A && git commit -m "update dotfiles"
git push
```

## License

MIT
