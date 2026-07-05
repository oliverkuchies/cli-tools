#!/usr/bin/env bash
#
# setup-dev-tools.sh
#
# Installs common CLI tools, configures ~/.zshrc and ~/.gitconfig,
# and creates useful aliases.
#
# Usage:
#   chmod +x setup-dev-tools.sh
#   ./setup-dev-tools.sh
#

set -euo pipefail

ZSHRC="$HOME/.zshrc"
GITCONFIG="$HOME/.gitconfig"

#######################################
# Homebrew
#######################################

if ! command -v brew >/dev/null 2>&1; then
    echo "Homebrew is not installed."
    echo "Install it first:"
    echo "https://brew.sh"
    exit 1
fi

#######################################
# Helpers
#######################################

append_if_missing() {
    local file="$1"
    local text="$2"

    touch "$file"

    if ! grep -Fq "$text" "$file"; then
        echo "$text" >> "$file"
    fi
}

install_brew() {
    local pkg="$1"

    if brew list "$pkg" >/dev/null 2>&1; then
        echo "✓ $pkg already installed"
    else
        echo "Installing $pkg..."
        brew install "$pkg"
    fi
}

install_cask() {
    local pkg="$1"

    if brew list --cask "$pkg" >/dev/null 2>&1; then
        echo "✓ $pkg already installed"
    else
        echo "Installing $pkg..."
        brew install --cask "$pkg"
    fi
}

#######################################
# Install tools
#######################################

brew update

install_brew bat
install_brew eza
install_brew fzf
install_brew zoxide
install_brew git-delta
install_brew lazygit
install_brew btop
install_brew kubectl
install_brew pnpm
install_brew starship

#######################################
# mise
#######################################

if [[ ! -x "$HOME/.local/bin/mise" ]]; then
    echo "Installing mise..."
    curl https://mise.run | sh
else
    echo "✓ mise already installed"
fi

#######################################
# fzf shell integration
#######################################

if [[ -d "$(brew --prefix)/opt/fzf" ]]; then
    "$(brew --prefix)/opt/fzf/install" \
        --key-bindings \
        --completion \
        --no-bash \
        --no-fish \
        --no-update-rc || true
fi

#######################################
# kubectl completion
#######################################

append_if_missing "$ZSHRC" 'source <(kubectl completion zsh)'

#######################################
# zsh configuration
#######################################

MARKER="# >>> Dev CLI Tools >>>"

if ! grep -Fq "$MARKER" "$ZSHRC"; then

cat >> "$ZSHRC" <<'EOF'

# >>> Dev CLI Tools >>>

# bat
alias cat="bat"
alias preview="bat"

# eza
alias ls="eza --icons --group-directories-first"
alias ll="eza -lah --icons --git"
alias lt="eza --tree --level=2 --icons"

# lazygit
alias lg="lazygit"

# btop
alias top="btop"

# fzf
eval "$(fzf --zsh)"

# zoxide
eval "$(zoxide init zsh)"

# mise
eval "$($HOME/.local/bin/mise activate zsh)"

# <<< Dev CLI Tools <<<

EOF

fi

#######################################
# git config (delta)
#######################################

git config --global core.pager delta
git config --global interactive.diffFilter "delta --color-only"
git config --global delta.navigate true
git config --global delta.side-by-side true
git config --global delta.line-numbers true

#######################################
# Install runtimes via mise
#######################################

if command -v mise >/dev/null 2>&1; then
    if [[ -f ".mise.toml" || -f ".tool-versions" ]]; then
        echo "Installing project runtimes..."
        mise install
    fi
fi

#######################################
# RTK reminder
#######################################

if [[ ! -x "$HOME/.local/bin/rtk" ]]; then
    cat <<EOF

==========================================================
RTK was not found.

Install it according to your RTK README so the binary ends up at:

  ~/.local/bin/rtk

No automatic installer was run because installation depends on
your local RTK distribution.
==========================================================

EOF
fi

########################################
## Starship (CLI Theme)
########################################
append_if_missing "$ZSHRC" 'eval "$(starship init zsh)"'

install_cask font-jetbrains-mono-nerd-font

echo "Dont forget to set your terminal font to JetBrains Mono Nerd Font in your terminal settings."

echo
echo "Done."
echo
echo "Restart your shell or run:"
echo
echo "    source ~/.zshrc"