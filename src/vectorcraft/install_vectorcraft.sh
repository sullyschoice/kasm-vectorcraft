#!/usr/bin/env bash
set -ex
SCRIPT_PATH="$( cd "$(dirname "$0")" ; pwd -P )"

REPO="storytold/vectorcraft"

# Map the Debian architecture to the naming used in the release assets
case "$(dpkg --print-architecture)" in
  amd64) ARCH="x86_64" ;;
  arm64) ARCH="aarch64" ;;
  *) echo "Unsupported architecture: $(dpkg --print-architecture)" >&2; exit 1 ;;
esac

apt-get update
apt-get install -y curl ca-certificates

# Use VECTORCRAFT_VERSION if given (e.g. 0.10.0), otherwise resolve the latest release tag.
# The /releases/latest redirect avoids the unauthenticated GitHub API rate limit.
if [ -z "${VECTORCRAFT_VERSION}" ]; then
  TAG=$(curl -fsSLI -o /dev/null -w '%{url_effective}' "https://github.com/${REPO}/releases/latest" | sed 's#.*/tag/##')
  VECTORCRAFT_VERSION="${TAG#v}"
fi

DEB="vectorcraft-${VECTORCRAFT_VERSION}-linux-${ARCH}.deb"
BASE_URL="https://github.com/${REPO}/releases/download/v${VECTORCRAFT_VERSION}"

mkdir -p /tmp/vectorcraft
cd /tmp/vectorcraft
curl -fsSL -o "${DEB}" "${BASE_URL}/${DEB}"
curl -fsSL -o SHA256SUMS.txt "${BASE_URL}/SHA256SUMS.txt"
grep " ${DEB}\$" SHA256SUMS.txt | sha256sum -c -

# Recommends pulls in mesa-vulkan-drivers / libegl-mesa0 for software rendering without a GPU
apt-get install -y --install-recommends "./${DEB}"

# Desktop shortcut
mkdir -p $HOME/Desktop
cp /usr/share/applications/ai.storyteller.vectorcraft.desktop $HOME/Desktop/
chmod +x $HOME/Desktop/ai.storyteller.vectorcraft.desktop
chown 1000:1000 $HOME/Desktop/ai.storyteller.vectorcraft.desktop

# Cleanup
cd /
rm -rf /tmp/vectorcraft
apt-get autoclean
rm -rf /var/lib/apt/lists/* /var/tmp/*
