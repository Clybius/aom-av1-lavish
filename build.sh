#!/bin/bash

# Build script for aom-lavish
# Builds the Endless_Merging branch and all patches inside ./patches

error() { echo -e "\033[31mERROR: $@\033[0m"; exit 1; }
warn() { echo -e "\033[33mWARNING: $@\033[0m"; }
success() { echo -e "\033[32mSUCCESS: $@\033[0m"; }
info() { echo -e "\033[34mINFO: $@\033[0m"; }

main() {
  local butteraugli=0
  local vmaf=0

  local optimize=''
  local static=''
  local jobs=$(nproc)

  local shared_libs=0
  local tests=0
  local docs=0

  while [[ "$#" -gt 0 ]]; do
    key="$1"
    case "$1" in
      -h|--help)
        echo
        echo "Usage: $0 [options]"
        echo "Options:"
        echo "  -v, --vmaf           Enable VMAF"
        echo "  -b, --butteraugli    Enable Butteraugli"
        echo "  -s, --shared-libs    Enable shared libraries"
        echo "  -t, --tests          Enable tests building"
        echo "  -d, --docs           Enable documentation building"
        echo "  -o, --optimize       Enable optimizations (-Ofast -flto -march=native)"
        echo "  -s, --static         Enable static linking"
        echo "  -j, --jobs <num>     Specify the number of jobs"
        echo "  -h, --help           Show this help message and exit"
        echo
        exit 0
        ;;
      -v|--vmaf) vmaf=1; shift;;
      -b|--butteraugli) butteraugli=1; shift;;
      -s|--shared-libs) shared_libs=1; shift;;
      -t|--tests) tests=1; shift;;
      -d|--docs) tests=1; shift;;
      -o|--optimize) optimize='-Ofast -flto -march=native'; shift;;
      -s|--static) static='-static'; shift;;
      -j|--jobs) jobs="$2"; shift; shift;;
      *) error "Unknown option: $key";;
    esac
  done

  readarray -t repo_files <<< $(ls -a1 | tail -n+3 | grep -ve 'build-' -e "${0##*/}" -e repo.tar)
  configure="cmake .. -DENABLE_DOCS=$docs -DENABLE_TESTS=$tests -DBUILD_SHARED_LIBS=$shared_libs -DCONFIG_TUNE_VMAF=$vmaf -DCONFIG_TUNE_BUTTERAUGLI=$butteraugli"
  build="make -j$jobs"

  build_component 'vanilla'
  mv build build-vanilla
  mkdir -p build
  cp -r build-vanilla/cmake build

  for patch in patches/*.patch; do
    rm -f repo.tar
    tar cf repo.tar "${repo_files[@]}"

    basename="${patch##*/}"
    custom_dir="build-${basename%.*}-patch"

    git apply "$patch" || error "Failed to apply patch $patch"
    build_component "$patch"

    rm -rf "$custom_dir"
    mv build "$custom_dir"
    mkdir build
    cp -r "$custom_dir/cmake" build

    rm -rf "${repo_files[@]}"
    tar xf repo.tar
  done
}

build_component() {
  local path="$PWD"
  local name="${1//-/ }"; name="${name//_/ }"
        name="${name##*/}"; name="${name%.*}"
  local build_dir="build"

  # Clean build files
  if [ -d "$build_dir/cmake" ]; then
    mv "$build_dir/cmake" "cmake-tmp"
    rm -rf "$build_dir" 2>/dev/null
    mkdir -p "$build_dir"
    mv "cmake-tmp" "$build_dir/cmake"
  fi

  # Run various build commands
  info "Building $name"
  cd "$build_dir"
  if [ -n "$configure" ]; then
    $configure -DCMAKE_CXX_FLAGS="$optimize $static" -DCMAKE_C_FLAGS="$optimize $static" \
    || error "Failed to configure $name"
  fi
  if [ -n "$build" ]; then $build || error "Failed to build $name"; fi
  cd "$path"
  success "Built $name"
}

main "$@"
