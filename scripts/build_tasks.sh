#!/usr/bin/env bash
set -e

INPUT_DIR=""
OUTPUT_DIR=""
CLEAN=0

usage() {
    echo "Usage: $0 -i <input_dir> [-o <output_dir>] [--cleanup]"
    echo ""
    echo "  -i, --input    Input tasks directory (required)"
    echo "  -o, --output   Output directory (default: <input_dir>/build)"
    echo "      --cleanup  Remove build_release dirs after building"
    exit 1
}

while [[ $# -gt 0 ]]; do
    case "$1" in
        -i|--input)
            [[ -z "${2-}" ]] && { echo "Error: --input requires a value"; usage; }
            INPUT_DIR="$2"; shift 2 ;;
        -o|--output)
            [[ -z "${2-}" ]] && { echo "Error: --output requires a value"; usage; }
            OUTPUT_DIR="$2"; shift 2 ;;
        --cleanup)
            CLEAN=1; shift ;;
        -h|--help)
            usage ;;
        *)
            echo "Error: unknown argument '$1'"; usage ;;
    esac
done

[[ -z "$INPUT_DIR" ]] && { echo "Error: --input is required"; usage; }
[[ ! -d "$INPUT_DIR" ]] && { echo "Error: input directory '$INPUT_DIR' does not exist"; exit 1; }

TASKS_DIR=$(realpath "$INPUT_DIR")
OUTPUT_DIR="${OUTPUT_DIR:-$TASKS_DIR/build}"

mkdir -p "$OUTPUT_DIR"

for TASK_PATH in "$TASKS_DIR"/*/; do
    [ -d "$TASK_PATH" ] || continue
    TASK_NAME=$(basename "$TASK_PATH")
    [ "$TASK_NAME" = "build" ] && continue
    [ ! -f "$TASK_PATH/CMakeLists.txt" ] && echo "==> SKIP $TASK_NAME (no CMakeLists.txt)" && continue

    echo "==> BUILD $TASK_NAME"
    cmake -S "$TASK_PATH" -B "$TASK_PATH/build_release" -G Ninja \
        -DCMAKE_BUILD_TYPE=Release \
        -DCMAKE_EXPORT_COMPILE_COMMANDS=OFF \
        > /dev/null 2>&1
    cmake --build "$TASK_PATH/build_release" --parallel 14 > /dev/null 2>&1

    DEST="$OUTPUT_DIR/$TASK_NAME"
    mkdir -p "$DEST"

    TARGET_DIR="$TASK_PATH/build_release/target"
    if [ -d "$TARGET_DIR" ]; then
        echo "==> COPY $TASK_NAME (from target/)"
        cp -r "$TARGET_DIR"/. "$DEST/"
    else
        BINARY=$(find "$TASK_PATH/build_release" -maxdepth 1 -type f -executable | head -n 1)
        if [ -n "$BINARY" ]; then
            echo "==> COPY $TASK_NAME (binary only: $(basename "$BINARY"))"
            cp "$BINARY" "$DEST/"
        else
            echo "==> WARN $TASK_NAME no binary found"
        fi
    fi

    for JSON_FILE in "$TASK_PATH"/*.json; do
        [ -f "$JSON_FILE" ] || continue
        echo "==> COPY $TASK_NAME (json: $(basename "$JSON_FILE"))"
        cp "$JSON_FILE" "$DEST/"
    done

    echo "==> DONE $TASK_NAME"

    if [ "$CLEAN" = "1" ] && [ -d "$TASK_PATH/build_release" ]; then
        echo "==> CLEAN $TASK_NAME"
        rm -rf "$TASK_PATH/build_release"
    fi
done

echo ""
echo "==> ALL DONE => $OUTPUT_DIR"
