#!/bin/sh
# Based on Deno installer: Copyright 2019 the Deno authors. All rights reserved. MIT license.
# TODO(everyone): Keep this script simple and easily auditable.

set -e

main() {
	os=$(uname -s | tr '[:upper:]' '[:lower:]')
	arch=$(uname -m)
	version=${1:-latest}

	zigup_uri="https://github.com/marler8997/zigup/releases/$version/download/zigup-$arch-$os.tar.gz"
	zigup_install="${ZIGUP_INSTALL:-$HOME/.zigup}"

	bin_dir="$zigup_install/bin"
	tmp_dir="$zigup_install/tmp"
	exe="$bin_dir/zigup"

	mkdir -p "$bin_dir"
	mkdir -p "$tmp_dir"

	curl -q --fail --location --progress-bar --output "$tmp_dir/zigup.tar.gz" "$zigup_uri"
	# extract to tmp dir so we don't open existing executable file for writing:
	tar -C "$tmp_dir" -xzf "$tmp_dir/zigup.tar.gz"
	chmod +x "$tmp_dir/zigup"
	# atomically rename into place:
	mv "$tmp_dir/zigup" "$exe"
	rm "$tmp_dir/zigup.tar.gz"

	echo "zigup was installed successfully to $exe"
	if command -v zigup >/dev/null; then
		echo "Run 'zigup' to get started"
	else
		case $SHELL in
		/bin/zsh) shell_profile=".zshrc" ;;
		*) shell_profile=".bash_profile" ;;
		esac
		echo "Manually add the directory to your \$HOME/$shell_profile (or similar)"
		echo "  export ZIGUP_INSTALL=\"$zigup_install\""
		echo "  export PATH=\"\$ZIGUP_INSTALL/bin:\$PATH\""
		echo "Run '$exe' to get started"
	fi
}

main "$1"
