#!/usr/bin/env bash
set -euo pipefail

ROOT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
# shellcheck disable=SC1091
source "${ROOT_DIR}/build/upstream.env"

WORK_DIR="${WORK_DIR:-${ROOT_DIR}/.work}"
SRC_DIR="${WORK_DIR}/rustdesk"
OUT_DIR="${OUT_DIR:-${ROOT_DIR}/dist/web}"

for cmd in git flutter curl tar npm yarn; do
  command -v "${cmd}" >/dev/null || {
    echo "Required command not found: ${cmd}" >&2
    exit 1
  }
done

rm -rf "${SRC_DIR}" "${OUT_DIR}"
mkdir -p "${WORK_DIR}" "${OUT_DIR}"

echo "==> Fetch RustDesk ${RUSTDESK_REF}"
git clone --filter=blob:none --no-checkout "${RUSTDESK_REPOSITORY}" "${SRC_DIR}"
git -C "${SRC_DIR}" fetch --depth=1 origin "${RUSTDESK_REF}"
git -C "${SRC_DIR}" checkout --detach FETCH_HEAD
git -C "${SRC_DIR}" submodule update --init --recursive --depth=1

actual_flutter="$(flutter --version | head -n1 | awk '{print $2}')"
if [[ "${actual_flutter}" != "${FLUTTER_VERSION}" ]]; then
  echo "Expected Flutter ${FLUTTER_VERSION}, found ${actual_flutter}." >&2
  exit 2
fi

# RustDesk's upstream web job patches the Flutter 3.24.5 SDK before building.
if [[ "${FLUTTER_VERSION}" == "3.24.5" ]]; then
  flutter_root="$(cd "$(dirname "$(dirname "$(command -v flutter)")")" && pwd)"
  flutter_patch="${SRC_DIR}/.github/patches/flutter_3.24.4_dropdown_menu_enableFilter.diff"

  if git -C "${flutter_root}" apply --check "${flutter_patch}" >/dev/null 2>&1; then
    echo "==> Patch Flutter ${FLUTTER_VERSION}"
    git -C "${flutter_root}" apply "${flutter_patch}"
  elif git -C "${flutter_root}" apply --reverse --check "${flutter_patch}" >/dev/null 2>&1; then
    echo "==> Flutter patch already applied"
  else
    echo "Unable to apply the RustDesk Flutter patch cleanly." >&2
    exit 3
  fi
fi

echo "==> Build RustDesk web JavaScript bridge"
pushd "${SRC_DIR}/flutter/web/js" >/dev/null
npm install typescript -g
npm install protoc -g
npm install ts-proto
npm install vite@2.8
yarn install
yarn build
popd >/dev/null

echo "==> Install RustDesk web dependency bundle"
pushd "${SRC_DIR}/flutter/web" >/dev/null
curl -fL --retry 3 "${WEB_DEPS_URL}" -o web_deps.tar.gz
tar xzf web_deps.tar.gz
rm web_deps.tar.gz
popd >/dev/null

echo "==> Build Flutter web client"
pushd "${SRC_DIR}/flutter" >/dev/null
flutter pub get
flutter build web --release
popd >/dev/null

cp -a "${SRC_DIR}/flutter/build/web/." "${OUT_DIR}/"
cp "${SRC_DIR}/flutter/web/README.md" "${OUT_DIR}/UPSTREAM-WEB-README.md" 2>/dev/null || true

cat > "${OUT_DIR}/BUILD-INFO.txt" <<EOF
RustDesk repository: ${RUSTDESK_REPOSITORY}
RustDesk ref: ${RUSTDESK_REF}
Flutter version: ${FLUTTER_VERSION}
EOF

echo "==> Web assets written to ${OUT_DIR}"
