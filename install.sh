#!/usr/bin/env bash
set -euo pipefail

GREEN='\033[0;32m'
YELLOW='\033[1;33m'
RED='\033[0;31m'
NC='\033[0m'
BOLD='\033[1m'

APP_REPO_SLUG="${NEXTONE_APP_REPO_SLUG:-s3d1K0/NextOne-Agent}"
BOOTSTRAP_REPO_SLUG="${NEXTONE_BOOTSTRAP_REPO_SLUG:-s3d1K0/homebrew-nextone}"
BOOTSTRAP_RAW_URL="${NEXTONE_BOOTSTRAP_RAW_URL:-https://raw.githubusercontent.com/s3d1K0/homebrew-nextone/main/install.sh}"
TAP_NAME="${NEXTONE_HOMEBREW_TAP:-s3d1K0/nextone}"
FORMULA_NAME="${NEXTONE_FORMULA_NAME:-nextone-agent}"

info() { echo -e "${GREEN}[✓]${NC} $1"; }
warn() { echo -e "${YELLOW}[!]${NC} $1"; }
fail() { echo -e "${RED}[✗]${NC} $1"; exit 1; }
step() { echo -e "\n${BOLD}→ $1${NC}"; }
current_github_user() { gh api user --jq .login 2>/dev/null || true; }
explain_repo_access_issue() {
  current_user="$(current_github_user)"
  echo ""
  echo "GitHub access is configured, but this account cannot read ${APP_REPO_SLUG}."
  if [[ -n "${current_user}" ]]; then
    echo "Current GitHub account: ${current_user}"
  fi
  echo ""
  echo "Do this:"
  echo "  1. Accept the invitation at: https://github.com/${APP_REPO_SLUG}/invitations"
  echo "  2. If this is the wrong account, run:"
  echo "     gh auth logout -h github.com"
  echo "     gh auth login --hostname github.com --git-protocol https --web --clipboard"
  echo "  3. Re-run this install command"
  echo ""
}

if [[ -z "${NEXTONE_BOOTSTRAP_TTY:-}" && ! -t 0 && -r /dev/tty ]]; then
  tmp_script="$(mktemp -t nextone-bootstrap.XXXXXX)"
  curl -fsSL "${BOOTSTRAP_RAW_URL}" -o "${tmp_script}"
  chmod +x "${tmp_script}"
  export NEXTONE_BOOTSTRAP_TTY=1
  exec /bin/bash "${tmp_script}" </dev/tty
fi

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
  echo "When prompted by gh, answer 'Y' to authenticate Git with your GitHub credentials."
  gh auth login --hostname github.com --git-protocol https --web --clipboard
fi
gh auth setup-git
info "GitHub auth ready"

step "Checking repo access"
if ! gh repo view "${APP_REPO_SLUG}" >/dev/null 2>&1; then
  explain_repo_access_issue
  fail "No access to ${APP_REPO_SLUG}. Ask Sedik for repo access first."
fi
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
