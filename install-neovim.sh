#!/bin/bash

# Install Neovim with LazyVim - global shared setup
# Simplified version for modern systems (Ubuntu 24.04+, Arch)
#
# Architecture:
#   - Neovim appimage at /usr/local/bin/nvim.appimage
#   - Wrapper script at /usr/local/bin/nvim (sets XDG_CONFIG_HOME)
#   - Global config at /opt/nvim/config/nvim/ (LazyVim starter)
#   - Global plugins at /opt/nvim/data/nvim/lazy/
#   - Per-user state: ~/.local/state/nvim/ (undo, shada, cache)

set -e

SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
# shellcheck source=lib/platform.sh
. "$SCRIPT_DIR/lib/platform.sh"

NVIM_GLOBAL="/opt/nvim"

echo ">> Installing Neovim..."

if command -v nvim &>/dev/null; then
  echo "Neovim is already installed: $(nvim --version | head -1)"
  exit 0
fi

# Install dependencies
case "$OS" in
  ubuntu)
    pkg_install libfuse2 xauth xclip ripgrep fd-find build-essential
    # Symlink fdfind -> fd (Ubuntu package name quirk)
    if ! command -v fd &>/dev/null && command -v fdfind &>/dev/null; then
      sudo ln -sf "$(command -v fdfind)" /usr/local/bin/fd
    fi
    ;;
  arch)
    pkg_install ripgrep fd
    ;;
esac

# Install python-lsp-server via uv if available
if command -v uv &>/dev/null; then
  echo "Installing python-lsp-server via uv..."
  sudo env HOME=/root UV_CACHE_DIR=/root/.cache/uv \
    UV_TOOL_DIR=/usr/local/share/uv/tools UV_TOOL_BIN_DIR=/usr/local/bin \
    uv tool install --force python-lsp-server \
    --with python-lsp-black \
    --with python-lsp-isort \
    --with pylsp-mypy || echo "Warning: Failed to install python-lsp-server via uv"
fi

# Install ruff via uv if available (avoids Mason's broken python3 spawn)
if command -v uv &>/dev/null; then
  echo "Installing ruff via uv..."
  sudo env HOME=/root UV_CACHE_DIR=/root/.cache/uv \
    UV_TOOL_DIR=/usr/local/share/uv/tools UV_TOOL_BIN_DIR=/usr/local/bin \
    uv tool install --force ruff || echo "Warning: Failed to install ruff via uv"
fi

# Download Neovim appimage
echo "Downloading Neovim appimage..."
case "$PLATFORM_ARCH_ALT" in
  x86_64)
    NVIM_APPIMAGE="nvim-linux-x86_64.appimage"
    ;;
  aarch64)
    NVIM_APPIMAGE="nvim-linux-arm64.appimage"
    ;;
  *)
    echo "ERROR: Unsupported architecture for Neovim: $PLATFORM_ARCH_ALT"
    exit 1
    ;;
esac

sudo curl -Lo /usr/local/bin/nvim.appimage \
  "https://github.com/neovim/neovim/releases/latest/download/${NVIM_APPIMAGE}"
sudo chmod +x /usr/local/bin/nvim.appimage

# Wrapper script: sets global config path
sudo tee /usr/local/bin/nvim > /dev/null << 'EOF'
#!/bin/bash
export XDG_CONFIG_HOME="/opt/nvim/config"
export NVIM_APPNAME="nvim"
exec /usr/local/bin/nvim.appimage "$@"
EOF
sudo chmod +x /usr/local/bin/nvim

# Alias 'n' for quick nvim launch
sudo tee /usr/local/bin/n > /dev/null << 'EOF'
#!/bin/bash
exec /usr/local/bin/nvim "$@"
EOF
sudo chmod +x /usr/local/bin/n

# Alias 'nx' for creating/editing executable scripts
sudo tee /usr/local/bin/nx > /dev/null << 'EOF'
#!/bin/bash
if [ -z "$1" ]; then
  echo "usage: nx <filename>"
  exit 1
fi
if [ ! -e "$1" ]; then
  printf '#!/usr/bin/env bash\n\nset -eo pipefail\n\n' > "$1"
fi
chmod -v 0755 "$1"
exec /usr/local/bin/nvim "$1"
EOF
sudo chmod +x /usr/local/bin/nx

# Create global directories
sudo mkdir -p "$NVIM_GLOBAL"/config/nvim
sudo mkdir -p "$NVIM_GLOBAL"/data/nvim/lazy

# Clone LazyVim starter
if [ ! -d "$NVIM_GLOBAL/config/nvim/lua" ]; then
  sudo git clone https://github.com/LazyVim/starter "$NVIM_GLOBAL/config/nvim"
  sudo rm -rf "$NVIM_GLOBAL/config/nvim/.git"
  # example.lua causes ensure_installed duplicates and parallel TS install errors
  sudo rm -f "$NVIM_GLOBAL/config/nvim/lua/plugins/example.lua"
fi

# Clone lazy.nvim manager
if [ ! -d "$NVIM_GLOBAL/data/nvim/lazy/lazy.nvim/.git" ]; then
  sudo rm -rf "$NVIM_GLOBAL/data/nvim/lazy/lazy.nvim"
  sudo git clone --filter=blob:none --branch=stable \
    https://github.com/folke/lazy.nvim.git \
    "$NVIM_GLOBAL/data/nvim/lazy/lazy.nvim"
fi

# Write lazy.lua configuration
sudo tee "$NVIM_GLOBAL/config/nvim/lua/config/lazy.lua" > /dev/null << 'EOF'
local uv = vim.uv or vim.loop

-- Global template (read-only, pre-installed by install-neovim.sh)
local global_root = "/opt/nvim/data/nvim/lazy"
-- Per-user writable copy (lazy.nvim operates here)
local user_root = vim.fn.stdpath("data") .. "/lazy"

-- Copy global plugins to user directory on first launch
if not uv.fs_stat(user_root) and uv.fs_stat(global_root) then
  vim.fn.mkdir(vim.fn.stdpath("data"), "p")
  os.execute('cp -a "' .. global_root .. '" "' .. user_root .. '"')
end

-- Also copy global treesitter parsers and mason tools on first launch
for _, subdir in ipairs({ "site", "mason" }) do
  local global_dir = "/opt/nvim/data/nvim/" .. subdir
  local user_dir = vim.fn.stdpath("data") .. "/" .. subdir
  if not uv.fs_stat(user_dir) and uv.fs_stat(global_dir) then
    vim.fn.mkdir(vim.fn.stdpath("data"), "p")
    os.execute('cp -a "' .. global_dir .. '" "' .. user_dir .. '"')
  end
end

local lazypath = user_root .. "/lazy.nvim"
if not uv.fs_stat(lazypath) then
  local lazyrepo = "https://github.com/folke/lazy.nvim.git"
  local out = vim.fn.system({ "git", "clone", "--filter=blob:none", "--branch=stable", lazyrepo, lazypath })
  if vim.v.shell_error ~= 0 then
    vim.api.nvim_echo({
      { "Failed to clone lazy.nvim:\n", "ErrorMsg" },
      { out, "WarningMsg" },
      { "\nPress any key to exit..." },
    }, true, {})
    vim.fn.getchar()
    os.exit(1)
  end
end
vim.opt.rtp:prepend(lazypath)

require("lazy").setup({
  root = user_root,
  change_detection = { enabled = false },
  rocks = { enabled = false },
  install = {
    missing = true,
    colorscheme = { "tokyonight", "habamax" },
  },
  spec = {
    { "LazyVim/LazyVim", import = "lazyvim.plugins" },
    { import = "lazyvim.plugins.extras.util.dot" },
    { import = "lazyvim.plugins.extras.lang.docker" },
    { import = "lazyvim.plugins.extras.lang.markdown" },
    { import = "lazyvim.plugins.extras.lang.python" },
    { import = "plugins" },
  },
  defaults = {
    lazy = false,
    version = false,
  },
  checker = {
    enabled = false,
    notify = false,
  },
  performance = {
    rtp = {
      disabled_plugins = {
        "gzip",
        "tarPlugin",
        "tohtml",
        "tutor",
        "zipPlugin",
      },
    },
  },
})
EOF

# Write options.lua with clipboard support (Wayland/X11/OSC52)
sudo mkdir -p "$NVIM_GLOBAL/config/nvim/lua/config"
sudo tee "$NVIM_GLOBAL/config/nvim/lua/config/options.lua" > /dev/null << 'LUAEOF'
-- Options are automatically loaded before lazy.nvim startup
-- Default options: https://github.com/LazyVim/LazyVim/blob/main/lua/lazyvim/config/options.lua

local env = vim.env
local opt = vim.opt
local exe = vim.fn.executable
local uv = vim.uv or vim.loop

-- Environment detection
local has_wayland = env.WAYLAND_DISPLAY and exe("wl-copy") == 1 and exe("wl-paste") == 1

local function x11_socket_ok()
  local display = env.DISPLAY or ""
  if display:match("^:") then
    return uv.fs_stat("/tmp/.X11-unix/X0") or uv.fs_stat("/mnt/wslg/.X11-unix/X0")
  end
  return true
end

local has_x11 = env.DISPLAY
  and (exe("xclip") == 1 or exe("xsel") == 1)
  and x11_socket_ok()

-- Helper: paste with CR removal
local function paste_clean(cmd)
  return function()
    local handle = io.popen(cmd)
    if not handle then
      return { { "" }, "v" }
    end
    local text = handle:read("*a") or ""
    handle:close()
    text = text:gsub("\r", "")
    local lines = vim.split(text, "\n", { plain = true })
    return { lines, "v" }
  end
end

-- Helper: OSC52 paste from register + strip CR
local function paste_from_reg(regname)
  return function()
    local text = vim.fn.getreg(regname)
    text = text:gsub("\r", "")
    local lines = vim.split(text, "\n", { plain = true })
    return { lines, vim.fn.getregtype(regname) }
  end
end

-- Wayland clipboard
if has_wayland then
  opt.clipboard = "unnamedplus"
  vim.g.clipboard = {
    name = "Wayland (wl-clipboard, clean CR)",
    copy = {
      ["+"] = "wl-copy",
      ["*"] = "wl-copy",
    },
    paste = {
      ["+"] = paste_clean("wl-paste"),
      ["*"] = paste_clean("wl-paste"),
    },
  }
-- X11 clipboard
elseif has_x11 then
  opt.clipboard = "unnamedplus"
  local copy_cmd = exe("xclip") == 1
      and "xclip -selection clipboard -i"
      or "xsel --clipboard --input"
  local paste_cmd = exe("xclip") == 1
      and "xclip -selection clipboard -o"
      or "xsel --clipboard --output"
  vim.g.clipboard = {
    name = "X11 clipboard (clean CR)",
    copy = {
      ["+"] = copy_cmd,
      ["*"] = copy_cmd,
    },
    paste = {
      ["+"] = paste_clean(paste_cmd),
      ["*"] = paste_clean(paste_cmd),
    },
  }
-- OSC52 fallback (SSH / WezTerm)
else
  opt.clipboard = "unnamedplus"
  local osc52 = require("vim.ui.clipboard.osc52")
  local function osc52_copy(reg)
    local f = osc52.copy(reg)
    return function(lines, regtype)
      if not pcall(f, lines, regtype) then
        pcall(f, lines)
      end
    end
  end
  vim.g.clipboard = {
    name = "OSC52 (copy-only; paste from reg0, clean CR)",
    copy = {
      ["+"] = osc52_copy("+"),
      ["*"] = osc52_copy("*"),
    },
    paste = {
      ["+"] = paste_from_reg("0"),
      ["*"] = paste_from_reg("0"),
    },
  }
end
LUAEOF

# Write pylsp.lua configuration
sudo mkdir -p "$NVIM_GLOBAL/config/nvim/lua/plugins"
sudo tee "$NVIM_GLOBAL/config/nvim/lua/plugins/pylsp.lua" > /dev/null << 'LUAEOF'
return {
  {
    "neovim/nvim-lspconfig",
    opts = function(_, opts)
      opts.servers = opts.servers or {}

      local uv = vim.uv or vim.loop
      local function exists(path)
        return path and uv.fs_stat(path) ~= nil
      end

      local function re_escape(s)
        return (s:gsub("([%^%$%(%)%%%.%[%]%*%+%-%?%{%}%|%\\])", "\\%1"))
      end

      local function detect_project_python(root_dir)
        local ve = vim.env.VIRTUAL_ENV
        if ve and ve ~= "" then
          local p = ve .. "/bin/python"
          if exists(p) then return p end
        end
        if root_dir and root_dir ~= "" then
          local p1 = root_dir .. "/venv/bin/python"
          if exists(p1) then return p1 end
          local p2 = root_dir .. "/.venv/bin/python"
          if exists(p2) then return p2 end
        end
        return nil
      end

      opts.servers.pylsp = {
        mason = false,
        settings = {
          pylsp = {
            plugins = {
              pycodestyle = { enabled = false },
              pyflakes = { enabled = false },
              mccabe = { enabled = false },
              black = { enabled = true },
              isort = { enabled = true },
              pylsp_mypy = {
                enabled = true,
                live_mode = false,
                exclude = { "site-packages/" },
                overrides = { true },
              },
            },
          },
        },
        on_new_config = function(new_config, root_dir)
          if root_dir and root_dir ~= "" and root_dir ~= "/" then
            local root_re = re_escape(root_dir)
            table.insert(
              new_config.settings.pylsp.plugins.pylsp_mypy.exclude,
              "^(?!" .. root_re .. "/).*"
            )
          end
          local py = detect_project_python(root_dir)
          if py then
            new_config.settings.pylsp.plugins.pylsp_mypy.overrides = {
              "--python-executable",
              py,
              true,
            }
          end
        end,
      }
    end,
  },
}
LUAEOF

# Write treesitter-parsers.lua (compile to user-writable location)
sudo tee "$NVIM_GLOBAL/config/nvim/lua/plugins/treesitter-parsers.lua" > /dev/null << 'LUAEOF'
return {
  {
    "nvim-treesitter/nvim-treesitter",
    opts = function(_, opts)
      local dir = vim.fn.stdpath("data") .. "/site"
      vim.fn.mkdir(dir, "p")
      opts.parser_install_dir = dir
      opts.install_dir = dir
      vim.opt.runtimepath:prepend(dir)
      -- Deduplicate ensure_installed to prevent parallel install errors
      if type(opts.ensure_installed) == "table" then
        local seen, out = {}, {}
        for _, lang in ipairs(opts.ensure_installed) do
          if not seen[lang] then
            seen[lang] = true
            table.insert(out, lang)
          end
        end
        opts.ensure_installed = out
      end
    end,
  },
}
LUAEOF

# Write mason-lspconfig overrides (use pylsp instead of pyright for Python)
sudo tee "$NVIM_GLOBAL/config/nvim/lua/plugins/mason-overrides.lua" > /dev/null << 'LUAEOF'
return {
  -- ruff: installed via uv, not Mason (avoids broken python3 spawn)
  {
    "neovim/nvim-lspconfig",
    opts = {
      servers = {
        ruff = { mason = false },
      },
    },
  },

  -- mason-lspconfig: auto-install all configured servers
  {
    "mason-org/mason-lspconfig.nvim",
    opts = function(_, opts)
      opts.automatic_installation = true
    end,
  },

  -- mason-tool-installer: disable auto-run (we pre-install in headless)
  {
    "WhoIsSethDaniel/mason-tool-installer.nvim",
    optional = true,
    opts = function(_, opts)
      opts.auto_update = false
      opts.run_on_start = false
    end,
  },
}
LUAEOF

# X11 forwarding setup (sudoers + XAUTHORITY)
if [ ! -f /etc/sudoers.d/x11-forward ]; then
  echo 'Defaults env_keep += "DISPLAY XAUTHORITY"' | sudo tee /etc/sudoers.d/x11-forward > /dev/null
  sudo chmod 440 /etc/sudoers.d/x11-forward
fi

if ! grep -q 'XAUTHORITY' /etc/profile 2>/dev/null; then
  sudo tee -a /etc/profile > /dev/null << 'EOF'

# X11 forwarding: set XAUTHORITY if DISPLAY is set but XAUTHORITY is not
if [ -n "$DISPLAY" ] && [ -z "$XAUTHORITY" ]; then
  export XAUTHORITY="$HOME/.Xauthority"
fi
EOF
fi

sudo touch /etc/skel/.Xauthority
sudo chmod 600 /etc/skel/.Xauthority

# Headless plugin installation (must run as root to write to /opt/nvim)
echo "Installing Neovim plugins (headless)..."
# XDG_DATA_HOME=/opt/nvim/data so plugins + treesitter parsers install into the global template

# Resolve mise-managed node path so npm is available inside sudo for Mason
MISE_NODE_BIN=""
if command -v mise &>/dev/null; then
  MISE_NODE_DIR="$(mise where node 2>/dev/null || true)"
  if [ -n "$MISE_NODE_DIR" ]; then
    MISE_NODE_BIN="$MISE_NODE_DIR/bin"
  fi
fi

# shellcheck disable=SC2016 # intentional: $i must expand inside bash -c, not here
sudo timeout 600 env \
  MISE_NODE_BIN="${MISE_NODE_BIN}" \
  bash -c '
  export XDG_CONFIG_HOME="/opt/nvim/config"
  export XDG_DATA_HOME="/opt/nvim/data"
  export HOME="/root"
  [ -n "$MISE_NODE_BIN" ] && export PATH="$MISE_NODE_BIN:$PATH"

  # Clean stale root nvim data from previous installs (without XDG_DATA_HOME)
  rm -rf /root/.local/share/nvim

  echo "Step 1/3: Installing plugins..."
  for i in 1 2 3; do
    /usr/local/bin/nvim.appimage --headless "+Lazy! sync" +qa 2>/dev/null
    echo "Plugin sync attempt $i completed"
    sleep 1
  done

  echo "Step 2/3: Installing Mason tools..."
  /usr/local/bin/nvim.appimage --headless \
    -c "lua require(\"lazy\").load({plugins=\"mason.nvim\"})" \
    -c "MasonInstall tree-sitter-cli lua-language-server marksman bash-language-server pyright dockerfile-language-server docker-compose-language-service" \
    -c "qall" 2>&1 || \
    echo "Mason install failed - tools will install on first launch"

  echo "Step 3/3: Installing TreeSitter parsers..."
  /usr/local/bin/nvim.appimage --headless \
    -c "lua require(\"lazy\").load({plugins=\"nvim-treesitter\"}); require(\"nvim-treesitter\").install({\"bash\",\"c\",\"css\",\"diff\",\"dockerfile\",\"go\",\"html\",\"javascript\",\"json\",\"lua\",\"luadoc\",\"luap\",\"markdown\",\"markdown_inline\",\"python\",\"query\",\"regex\",\"rst\",\"toml\",\"tsx\",\"typescript\",\"vim\",\"vimdoc\",\"xml\",\"yaml\"}):wait(300000)" \
    -c "qall" 2>&1 || \
    echo "TreeSitter install failed - parsers will install on first launch"
'

# Set read-only permissions for global directory
sudo chmod -R 755 "$NVIM_GLOBAL"
sudo chown -R root:root "$NVIM_GLOBAL"

echo ">> Neovim installed: $(/usr/local/bin/nvim.appimage --version | head -1)"
echo "  Config:  $NVIM_GLOBAL/config/nvim/"
echo "  Plugins: $NVIM_GLOBAL/data/nvim/lazy/"
echo "  User state: ~/.local/state/nvim/ (per-user undo, shada)"
