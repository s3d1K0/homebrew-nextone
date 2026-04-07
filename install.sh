#!/usr/bin/env bash
set -euo pipefail

GREEN='\033[0;32m'
YELLOW='\033[1;33m'
RED='\033[0;31m'
NC='\033[0m'
BOLD='\033[1m'

APP_REPO_SLUG="${NEXTONE_APP_REPO_SLUG:-s3d1K0/NextOne-Agent}"
BOOTSTRAP_REPO_SLUG="${NEXTONE_BOOTSTRAP_REPO_SLUG:-s3d1K0/homebrew-nextone}"
TAP_NAME="${NEXTONE_HOMEBREW_TAP:-s3d1K0/nextone}"
FORMULA_NAME="${NEXTONE_FORMULA_NAME:-nextone-agent}"

info() { echo -e "${GREEN}[✓]${NC} $1"; }
warn() { echo -e "${YELLOW}[!]${NC} $1"; }
fail() { echo -e "${RED}[✗]${NC} $1"; exit 1; }
step() { echo -e "\n${BOLD}→ $1${NC}"; }

echo ""
echo "╔══════════════════════════════════════╗"
echo "║   NextOne Agent — Bootstrap         ║"
echo "╚══════════════════════════════════════╝"
echo ""

step "Checking Homebrew"
if ! command -v brew >/dev/null 2>&1; then
  warn "Homebrew not found. Installing..."
  /bin/bash -c "$(curl -fsSL https://raw.githubusercontent.com/Homebrew/install/HEAD/install.sh)"
fi

if [[ -x /opt/homebrew/bin/brew ]]; then
  eval "$(/opt/homebrew/bin/brew shellenv)"
elif [[ -x /usr/local/bin/brew ]]; then
  eval "$(/usr/local/bin/brew shellenv)"
fi
command -v brew >/dev/null 2>&1 || fail "brew is still unavailable after installation"
info "$(brew --version | head -1)"

step "Checking GitHub CLI"
if ! command -v gh >/dev/null 2>&1; then
  brew install gh
fi
info "$(gh --version | head -1)"

step "Authenticating GitHub"
if ! gh auth status >/dev/null 2>&1; then
  gh auth login
fi
gh auth setup-git
info "GitHub auth ready"

step "Checking repo access"
gh repo view "${APP_REPO_SLUG}" >/dev/null 2>&1 || fail "No access to ${APP_REPO_SLUG}. Ask Sedik for repo access first."
info "Access confirmed to ${APP_REPO_SLUG}"

step "Installing NextOne bootstrap CLI"
brew tap "${TAP_NAME}" "https://github.com/${BOOTSTRAP_REPO_SLUG}.git"
if ! brew list --formula "${FORMULA_NAME}" >/dev/null 2>&1; then
  brew install "${FORMULA_NAME}"
else
  brew upgrade "${FORMULA_NAME}" || true
fi

NEXTONE_BIN="$(command -v nextone || true)"
if [[ -z "${NEXTONE_BIN}" ]]; then
  if [[ -x /opt/homebrew/bin/nextone ]]; then
    NEXTONE_BIN=/opt/homebrew/bin/nextone
  elif [[ -x /usr/local/bin/nextone ]]; then
    NEXTONE_BIN=/usr/local/bin/nextone
  fi
fi
[[ -n "${NEXTONE_BIN}" ]] || fail "nextone CLI not found after installation"
info "nextone installed at ${NEXTONE_BIN}"

step "Running guided setup"
export NEXTONE_APP_REPO_SLUG="${APP_REPO_SLUG}"
"${NEXTONE_BIN}" setup

echo ""
echo "╔══════════════════════════════════════╗"
echo "║   NextOne is ready                  ║"
echo "╚══════════════════════════════════════╝"
echo ""
echo "Useful commands:"
echo "  nextone setup            # re-run AI/MCP configuration"
echo "  nextone update           # update repo + CLI"
echo "  nextone tools            # list tools"
echo "  nextone doctor           # health check (inside your AI client)"
echo ""
