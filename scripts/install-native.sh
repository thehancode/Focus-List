#!/usr/bin/env bash
set -euo pipefail

repo_dir="$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")/.." && pwd)"
binary_source="$repo_dir/target/release/tui-kanban-native"
data_home="${XDG_DATA_HOME:-$HOME/.local/share}"
config_home="${XDG_CONFIG_HOME:-$HOME/.config}"
bin_home="$HOME/.local/bin"
install_dir="$data_home/tui-kanban/bin"
icon_dir="$data_home/icons/hicolor/scalable/apps"
applications_dir="$data_home/applications"
autostart_dir="$config_home/autostart"

if [[ "${1:-}" != "--skip-build" ]]; then
    cargo build --release --bin tui-kanban-native --manifest-path "$repo_dir/Cargo.toml"
fi

if [[ ! -x "$binary_source" ]]; then
    echo "Native release binary not found: $binary_source" >&2
    exit 1
fi

mkdir -p "$bin_home" "$install_dir" "$icon_dir" "$applications_dir" "$autostart_dir"

# Replace atomically: an already-open copy can finish normally while the next
# launch receives the newly built executable.
binary_tmp="$install_dir/.tui-kanban-native.new.$$"
trap 'rm -f -- "$binary_tmp"' EXIT
install -m 0755 "$binary_source" "$binary_tmp"
mv -f -- "$binary_tmp" "$install_dir/tui-kanban-native"
trap - EXIT

install -m 0644 "$repo_dir/assets/tui-kanban.svg" "$icon_dir/tui-kanban.svg"
install -m 0755 "$repo_dir/scripts/tui-kanban-native-launcher" "$bin_home/tui-kanban-native"

sed "s|@HOME@|$HOME|g" "$repo_dir/packaging/tui-kanban.desktop.in" \
    > "$applications_dir/tui-kanban.desktop"
chmod 0644 "$applications_dir/tui-kanban.desktop"

sed "s|@HOME@|$HOME|g" "$repo_dir/packaging/tui-kanban-autostart.desktop.in" \
    > "$autostart_dir/tui-kanban.desktop"
chmod 0644 "$autostart_dir/tui-kanban.desktop"

if command -v update-desktop-database >/dev/null 2>&1; then
    update-desktop-database "$applications_dir" >/dev/null 2>&1 || true
fi

echo "Installed Focus List. It will open automatically at the next login."
echo "Future updates: $repo_dir/scripts/install-native.sh"
