#!/usr/bin/env bash
set -euo pipefail

ROOT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
# shellcheck disable=SC1091
source "${ROOT_DIR}/build/baseline.env"

WORK_DIR="${WORK_DIR:-${ROOT_DIR}/.work}"
PACKAGING_DIR="${WORK_DIR}/docker-rustdesk-web-client"
IMAGE_TAG="${IMAGE_TAG:-rustdesk-web-stack:ci}"
OUT_DIR="${OUT_DIR:-${ROOT_DIR}/dist/web}"

for cmd in git docker; do
  command -v "${cmd}" >/dev/null || {
    echo "Required command not found: ${cmd}" >&2
    exit 1
  }
done

rm -rf "${PACKAGING_DIR}" "${OUT_DIR}"
mkdir -p "${WORK_DIR}" "${OUT_DIR}"

echo "==> Fetch packaging source ${PACKAGING_REF}"
git clone --filter=blob:none --no-checkout "${PACKAGING_REPOSITORY}" "${PACKAGING_DIR}"
git -C "${PACKAGING_DIR}" fetch --depth=1 origin "${PACKAGING_REF}"
git -C "${PACKAGING_DIR}" checkout --detach FETCH_HEAD

actual_packaging_ref="$(git -C "${PACKAGING_DIR}" rev-parse HEAD)"
[[ "${actual_packaging_ref}" == "${PACKAGING_REF}" ]] || {
  echo "Packaging ref mismatch: ${actual_packaging_ref}" >&2
  exit 2
}

echo "==> Build RustDesk Web baseline image"
docker build \
  --file "${PACKAGING_DIR}/Dockerfile" \
  --build-arg "RUSTDESK_REPO=${WEB_CLIENT_REPOSITORY}" \
  --build-arg "RUSTDESK_COMMIT=${WEB_CLIENT_REF}" \
  --build-arg "FLUTTER_VERSION=${FLUTTER_VERSION}" \
  --build-arg "RUST_VERSION=${RUST_VERSION}" \
  --build-arg "ENABLE_WSS=${ENABLE_WSS}" \
  --tag "${IMAGE_TAG}" \
  "${PACKAGING_DIR}"

echo "==> Extract static web artifact"
container_id="$(docker create "${IMAGE_TAG}")"
trap 'docker rm -f "${container_id}" >/dev/null 2>&1 || true' EXIT
docker cp "${container_id}:/usr/share/nginx/html/." "${OUT_DIR}/"
docker rm "${container_id}" >/dev/null
trap - EXIT

test -s "${OUT_DIR}/index.html"

cat > "${OUT_DIR}/BUILD-INFO.txt" <<EOF
Packaging repository: ${PACKAGING_REPOSITORY}
Packaging ref: ${PACKAGING_REF}
Web client repository: https://github.com/${WEB_CLIENT_REPOSITORY}.git
Web client ref: ${WEB_CLIENT_REF}
Flutter version: ${FLUTTER_VERSION}
Rust version: ${RUST_VERSION}
WSS patch enabled: ${ENABLE_WSS}
EOF

echo "==> Image: ${IMAGE_TAG}"
echo "==> Web assets: ${OUT_DIR}"
