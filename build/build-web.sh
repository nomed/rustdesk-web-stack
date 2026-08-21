#!/usr/bin/env bash
set -euo pipefail

ROOT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
# shellcheck disable=SC1091
source "${ROOT_DIR}/build/upstream.env"

WORK_DIR="${WORK_DIR:-${ROOT_DIR}/.work}"
SRC_DIR="${WORK_DIR}/rustdesk"
OUT_DIR="${OUT_DIR:-${ROOT_DIR}/dist/web}"

command -v git >/dev/null
command -v flutter >/dev/null
command -v curl >/dev/null
command -v tar >/dev/null

rm -rf "${SRC_DIR}" "${OUT_DIR}"
mkdir -p "${WORK_DIR}" "${OUT_DIR}"

git clone --filter=blob:none --no-checkout "${RUSTDESK_REPOSITORY}" "${SRC_DIR}"
git -C "${SRC_DIR}" fetch --depth=1 origin "${RUSTDESK_REF}"
git -C "${SRC_DIR}" checkout --detach FETCH_HEAD
git -C "${SRC_DIR}" submodule update --init --recursive --depth=1

actual_flutter="$(flutter --version | head -n1 | awk '{print $2}')"
if [[ "${actual_flutter}" != "${FLUTTER_VERSION}" ]]; then
  echo "Expected Flutter ${FLUTTER_VERSION}, found ${actual_flutter}." >&2
  exit 2
fi

# RustDesk's upstream Web Client CI recipe downloads additional web assets
# before invoking `flutter build web --release`.
pushd "${SRC_DIR}/flutter/web" >/dev/null
curl -fL "${WEB_DEPS_URL}" -o web_deps.tar.gz
tar xzf web_deps.tar.gz
rm web_deps.tar.gz
popd >/dev/null

# NOTE: upstream also builds JavaScript dependencies before this step.
# The exact JS build path is intentionally not guessed here; this script will
# fail fast until that part of the disabled upstream job is reproduced and
# verified in this repository.
if [[ ! -d "${SRC_DIR}/flutter/web/js" ]]; then
  echo "RustDesk web JS build inputs are not present after dependency extraction." >&2
  echo "The upstream web build recipe must be completed before this script is production-ready." >&2
  exit 3
fi

pushd "${SRC_DIR}/flutter" >/dev/null
flutter pub get
flutter build web --release
popd >/dev/null

cp -a "${SRC_DIR}/flutter/build/web/." "${OUT_DIR}/"
echo "Web assets written to ${OUT_DIR}"
