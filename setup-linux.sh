#!/bin/bash
# Builds the native Linux version of this game from YOUR OWN disc image.
# Usage:   ./setup-linux.sh /path/to/your/game.rvz
# Nothing from the game is downloaded or stored in this repository: the disc's code is
# translated and compiled on your PC, into ./build and ./play.
set -euo pipefail
HERE=$(cd "$(dirname "$0")" && pwd)
DISC=${1:?usage: ./setup-linux.sh /path/to/your/game.rvz}
[ -f "$DISC" ] || { echo "Can't find the disc image $DISC"; exit 1; }
field() { python3 -c "import json,sys; g=json.load(open('$HERE/game.json')); print(eval('g' + sys.argv[1]))" "$1"; }
ID=$(field "['id']"); REPO=$(field "['runtime']['repository']"); COMMIT=$(field "['runtime']['commit']")
BREAKPOINTS=$(field "['fifo_breakpoints']")

# 1. Tools (Debian, Ubuntu and their relatives; other distributions: install the same).
PACKAGES="clang ninja-build python3 git cmake pkg-config libglfw3-dev libvulkan-dev libshaderc-dev libasound2-dev
  mesa-vulkan-drivers libudev-dev libusb-1.0-0-dev libx11-dev libxext-dev libxrandr-dev libxcursor-dev libxi-dev
  libxss-dev libxtst-dev libxkbcommon-dev libwayland-dev libdbus-1-dev"
if command -v apt-get >/dev/null; then
  MISSING=$(for p in $PACKAGES; do dpkg-query -W -f='${Status}' "$p" 2>/dev/null | grep -q 'install ok installed' || echo "$p"; done)
  if [ -n "$MISSING" ]; then
    echo "Installing the missing build packages (needs sudo):" $MISSING
    sudo apt-get install -y $MISSING
  fi
fi

# 2. The runtime, at the version this game was tested with, and SDL3 for controllers.
RUNTIME=$HERE/build/runtime
[ -d "$RUNTIME/.git" ] || git clone --quiet "$REPO" "$RUNTIME"
git -C "$RUNTIME" fetch --quiet origin
git -C "$RUNTIME" checkout --quiet "$COMMIT"
if ! ls "$HOME"/.local/lib*/libSDL3.so* >/dev/null 2>&1 && ! pkg-config --exists sdl3 2>/dev/null; then
  "$RUNTIME/recomp/tools/sdl3_setup.sh" --prefix "$HOME/.local"
fi
export SDL3_PREFIX=$HOME/.local

# 3. Translate and compile the game from the disc, and pack it as one image. The profile from
#    testing says which code runs most, so that part is compiled for speed from the start.
FOLDER=$(field ".get('title_folder', '')")
if [ -n "$FOLDER" ] && [ -f "$HERE/profile.txt" ] && [ ! -f "$RUNTIME/recomp/build/title-data/$FOLDER/profile.txt" ]; then
  mkdir -p "$RUNTIME/recomp/build/title-data/$FOLDER"
  cp "$HERE/profile.txt" "$RUNTIME/recomp/build/title-data/$FOLDER/"
fi
ARGS=("$DISC")
[ "$BREAKPOINTS" = True ] && ARGS+=(--fifo-breakpoints)
python3 "$RUNTIME/recomp/tools/add_game.py" "${ARGS[@]}"
GOT=$(head -c 6 "$RUNTIME"/recomp/build-*/disc/sys/boot.bin 2>/dev/null | head -c 6 || true)
[ -n "$GOT" ] && [ "$GOT" != "$ID" ] && echo "Note: your disc is $GOT; this repository was tested with $ID. It may still work."

# 4. A folder you can play from.
PLAY=$HERE/play
mkdir -p "$PLAY/games"
cp "$RUNTIME/recomp/build/wii-recomp" "$PLAY/"
cp "$RUNTIME"/games/*.wrd "$PLAY/games/"
IMAGE=$(basename "$(ls "$PLAY"/games/*.wrd | head -1)")
cat > "$PLAY/play.sh" <<EOF2
#!/bin/bash
cd "\$(dirname "\$0")"
export LD_LIBRARY_PATH="\$HOME/.local/lib:\${LD_LIBRARY_PATH:-}"
exec ./wii-recomp "games/$IMAGE"
EOF2
chmod +x "$PLAY/play.sh" "$PLAY/wii-recomp"
echo
echo "Done. Start the game with $PLAY/play.sh"
echo "Controls are set in $PLAY/controllers.ini (written on the first start)."
