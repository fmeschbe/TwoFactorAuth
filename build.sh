#!/bin/sh

# NOTE on server domain:
# The server domain is configured in two locations:
#    - config.php for the QR code title (might also be another name !!) and the default redirect URL
#    - nginx/http.d/default for the servername
#
# We need to define two execution environment variables which will
# configure the server on first run through a /etc/cont-init.d/99-setup script:
#
#    QR_CODE_TITLE
#    SERVER_NAME
#

# decide on what to build here ...
MACHINE_ARCH=$(uname -m)
case "${MACHINE_ARCH}" in
  armv7l)
    echo "Building for 32bit ARM"
    ARCH="armhf"
    ARCH_TAG="arm32v7"
    ;;
  aarch64|arm64)
    echo "Building for 64bit ARM"
    ARCH="aarm64"
    ARCH_TAG="arm64v8"
    ;;
  *)
    echo "Unknown/unsupported machine architecture '${MACHINE_ARCH}' - cannot build"
    exit 1
esac

# Create Docker file for build from template
sed "s/#{ARCH_TAG}/${ARCH_TAG}/g" Dockerfile-template > Dockerfile.${ARCH}

COMMIT_SHA=$(git rev-parse --short HEAD)
EXT_RELEASE="0.1-${COMMIT_SHA}"
EXT_RELEASE_CLEAN=$(echo ${EXT_RELEASE} | sed 's/[~,%@+;:/]//g')
VERSION_TAG="${EXT_RELEASE_CLEAN}-fme-1"
GITHUB_DATE=$(date '+%Y-%m-%dT%H:%M:%S%:z')
IMAGE="fmeschbe/twofactorauth"
META_TAG="${VERSION_TAG}"

docker build \
   --label "org.opencontainers.image.created=${GITHUB_DATE}" \
   --label "org.opencontainers.image.authors=fmeschbe" \
   --label "org.opencontainers.image.url=https://github.com/fmeschbe/TwoFactorAuth" \
   --label "org.opencontainers.image.documentation=https://github.com/fmeschbe/TwoFactorAuth" \
   --label "org.opencontainers.image.source=https://github.com/fmeschbe/TwoFactorAuth" \
   --label "org.opencontainers.image.version=${VERSION_TAG}" \
   --label "org.opencontainers.image.revision=${COMMIT_SHA}" \
   --label "org.opencontainers.image.vendor=meschberger.ch" \
   --label "org.opencontainers.image.licenses=GPL-3.0-only" \
   --label "org.opencontainers.image.ref.name=${COMMIT_SHA}" \
   --label "org.opencontainers.image.title=TwoFactorAuth" \
   --label "org.opencontainers.image.description=TwoFactorAuth is a web authentication portal providing two factor authentication(*2FA*)." \
   --no-cache \
   --pull \
   -f Dockerfile.${ARCH} \
   -t ${IMAGE}:${ARCH_TAG}-${META_TAG} \
   -t ${IMAGE}:latest \
   --build-arg VERSION=\"${VERSION_TAG}\" \
   --build-arg BUILD_DATE=${GITHUB_DATE} .

