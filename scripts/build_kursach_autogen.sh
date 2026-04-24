#!/usr/bin/env bash
set -e

OUTPUT_DIR=""
TMP_DIR=""
CLEAN=0

usage() {
    echo "Usage: $0 -o <output_dir> [-t <temp_dir>] [--cleanup]"
    echo ""
    echo "  -o, --output   Output directory for binary (required)"
    echo "  -t, --tmpdir   Directory for cloning and building (default: ./kursach_autogen_tmp)"
    echo "      --cleanup  Remove temp directory after build"
    exit 1
}

while [[ $# -gt 0 ]]; do
    case "$1" in
        -o|--output)
            [[ -z "${2-}" ]] && { echo "Error: --output requires a value"; usage; }
            OUTPUT_DIR="$2"; shift 2 ;;
        -t|--tmpdir)
            [[ -z "${2-}" ]] && { echo "Error: --tmpdir requires a value"; usage; }
            TMP_DIR="$2"; shift 2 ;;
        --cleanup)
            CLEAN=1; shift ;;
        -h|--help)
            usage ;;
        *)
            echo "Error: unknown argument '$1'"; usage ;;
    esac
done

[[ -z "$OUTPUT_DIR" ]] && { echo "Error: --output is required"; usage; }

TMP_DIR="${TMP_DIR:-./kursach_autogen_tmp}"
REPO_URL="https://github.com/koftamainee/kursach-autogen"

echo "==> CLONING kursach-autogen"
rm -rf "$TMP_DIR"
git clone "$REPO_URL" "$TMP_DIR" > /dev/null 2>&1

echo "==> BUILD"
cargo build --release --manifest-path "$TMP_DIR/Cargo.toml" > /dev/null 2>&1

mkdir -p "$OUTPUT_DIR"

BINARY=$(find "$TMP_DIR/target/release" -maxdepth 1 -type f -executable | head -n 1)
if [ -n "$BINARY" ]; then
    echo "==> COPY binary: $(basename "$BINARY")"
    cp "$BINARY" "$OUTPUT_DIR/"
else
    echo "==> WARN no binary found in target/release"
fi

if [ "$CLEAN" = "1" ]; then
    echo "==> CLEAN temp dir"
    rm -rf "$TMP_DIR"
fi

echo "==> DONE => $OUTPUT_DIR"
