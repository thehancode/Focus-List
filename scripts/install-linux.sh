#!/usr/bin/env bash
# Build and install the Linux release bundle for local use.
#
# Optional overrides:
#   FOCUS_LIST_INSTALL_DIR=/somewhere scripts/install-linux.sh
#   FOCUS_LIST_BIN_DIR=/somewhere/bin scripts/install-linux.sh

set -euo pipefail

repo_root="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
bundle_dir="$repo_root/build/linux/x64/release/bundle"
binary_name="flutter_app"
install_dir="${FOCUS_LIST_INSTALL_DIR:-$HOME/.local/opt/focus-list}"
bin_dir="${FOCUS_LIST_BIN_DIR:-$HOME/.local/bin}"
command_name="focus-list"
staging_dir="${install_dir}.new"
desktop_dir="${XDG_DATA_HOME:-$HOME/.local/share}/applications"
desktop_file="$desktop_dir/tui-kanban.desktop"
autostart_file="$HOME/.config/autostart/tui-kanban.desktop"

case "$install_dir" in
  /|"$HOME"|"$HOME/.local"|"$HOME/.local/opt")
    echo "Refusing unsafe install directory: $install_dir" >&2
    exit 1
    ;;
esac

cd "$repo_root"
flutter build linux --release

if [[ ! -x "$bundle_dir/$binary_name" ]]; then
  echo "Release bundle is missing $binary_name: $bundle_dir" >&2
  exit 1
fi

rm -rf "$staging_dir"
mkdir -p "$staging_dir"
cp -a "$bundle_dir/." "$staging_dir/"

mkdir -p "$(dirname "$install_dir")" "$bin_dir"
rm -rf "$install_dir"
mv "$staging_dir" "$install_dir"
ln -sfn "$install_dir/$binary_name" "$bin_dir/$command_name"

# Keep the existing Focus List menu and login entries, but point both at the
# Flutter application instead of the legacy Rust executable.
mkdir -p "$desktop_dir" "$(dirname "$autostart_file")"
cat >"$desktop_file" <<EOF
[Desktop Entry]
Type=Application
Name=Focus List
GenericName=Task List
Comment=Open your keyboard-first task list
Exec=$bin_dir/$command_name
Icon=tui-kanban
Terminal=false
Categories=Office;
StartupNotify=true
StartupWMClass=com.tuikanban.flutter_app
Keywords=focus;tasks;todo;
EOF

cat >"$autostart_file" <<EOF
[Desktop Entry]
Type=Application
Name=Focus List
Comment=Open Focus List at login
Exec=$bin_dir/$command_name
Icon=tui-kanban
Terminal=false
StartupNotify=false
X-GNOME-Autostart-enabled=true
OnlyShowIn=GNOME;Unity;
EOF

echo "Installed $command_name to $install_dir"
echo "Run it with: $bin_dir/$command_name"
