#!/usr/bin/env bash

set -e

clone_at_revision() {
    local dir="$1"
    local revision="$2"
    local remote="$3"
    shift 3
    [ -d "$dir" ] && return
    git clone "$@" "$remote" "$dir"
    if ! git -C "$dir" checkout --detach "$revision"; then
        git -C "$dir" fetch origin "$revision"
        git -C "$dir" checkout --detach FETCH_HEAD
    fi
    if [ -f "$dir/.gitmodules" ]; then
        git -C "$dir" submodule update --init --recursive
    fi
}

clone_at_revision SPIRV-Reflect ef913b3ab3da1becca3cf46b15a10667c67bebe5 https://github.com/KhronosGroup/SPIRV-Reflect --depth=1

arch_dir() {
    case "$(uname -m)" in
        x86_64 | amd64) echo "x64" ;;
        aarch64 | arm64) echo "arm64" ;;
        *) echo "$(uname -m)" ;;
    esac
}

echo "Building SPIRV-Reflect.."
cd SPIRV-Reflect
cmake . -B build -DSPIRV_REFLECT_EXECUTABLE=OFF -DSPIRV_REFLECT_STATIC_LIB=ON -DCMAKE_BUILD_TYPE=Release
if [ $(uname -s) = 'Darwin' ]; then
    make -j$(sysctl -n hw.ncpu) -C build
    ARTIFACT_DIR="darwin_$(arch_dir)"
    LIB_EXT=darwin
else
    make -j$(nproc) -C build
    ARTIFACT_DIR="linux_$(arch_dir)"
    LIB_EXT=linux
fi
mkdir -p "../$ARTIFACT_DIR"
cp build/libspirv-reflect-static.a "../$ARTIFACT_DIR/spirv.$LIB_EXT.a"
