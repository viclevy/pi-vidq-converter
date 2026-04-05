#!/bin/bash

WATCH_DIR="/app/recordings"  # Directory to monitor
MAX_AGE_DAYS=90              # Delete recordings older than this (roughly 3 months)
MIN_FILE_SIZE="600k"         # Delete converted files smaller than this

log() {
    echo "[$(date '+%Y-%m-%d %H:%M:%S')] $*"
}

# Delete recordings older than MAX_AGE_DAYS based on the date in the filename (YYYYMMDD_HHMMSS.mp4)
cleanup_old_files() {
    local cutoff_date count=0
    cutoff_date=$(date -d "-${MAX_AGE_DAYS} days" '+%Y%m%d')

    for f in "$WATCH_DIR"/*.mp4; do
        [ -e "$f" ] || continue
        local fname
        fname=$(basename "$f")
        local file_date="${fname%%_*}"
        # Skip files whose names don't start with a valid 8-digit date
        [[ "$file_date" =~ ^[0-9]{8}$ ]] || continue
        if [ "$file_date" -lt "$cutoff_date" ]; then
            log "Removing old file: $fname (recorded $file_date, cutoff $cutoff_date)"
            rm "$f"
            count=$((count + 1))
        fi
    done

    if [ "$count" -gt 0 ]; then
        log "Removed $count file(s) older than $MAX_AGE_DAYS days"
    fi
}

# Delete converted mp4 files that are too small (corrupt or trivial clips)
cleanup_small_files() {
    local count
    count=$(find "$WATCH_DIR" -maxdepth 1 -type f -name "*.mp4" -size -$MIN_FILE_SIZE | wc -l)
    if [ "$count" -gt 0 ]; then
        log "Removing $count mp4 file(s) smaller than $MIN_FILE_SIZE"
        find "$WATCH_DIR" -maxdepth 1 -type f -name "*.mp4" -size -$MIN_FILE_SIZE -print -delete
    fi
}

# Convert a .queued file to .mp4
process_file() {
    local FILE="$1"
    if [[ "$FILE" != *.queued ]]; then
        return
    fi

    local BASENAME="${FILE%.queued}"
    local INPUT_FILE="$WATCH_DIR/$FILE"
    local OUTPUT_FILE="$WATCH_DIR/$BASENAME.mp4"

    log "Converting $FILE -> $BASENAME.mp4"
    if ffmpeg -i "$INPUT_FILE" -vcodec libx264 -acodec aac "$OUTPUT_FILE" -y -loglevel warning; then
        rm "$INPUT_FILE"
        log "Conversion complete: $BASENAME.mp4"
        cleanup_small_files
    else
        log "ERROR: ffmpeg failed for $FILE — keeping original"
    fi
}

# --- Startup ---
log "Starting video conversion service"
log "Watching: $WATCH_DIR | Max age: ${MAX_AGE_DAYS}d | Min size: $MIN_FILE_SIZE"

cleanup_old_files

# Process any .queued files left over from downtime
for EXISTING_FILE in "$WATCH_DIR"/*.queued; do
    [ -e "$EXISTING_FILE" ] || continue
    process_file "$(basename "$EXISTING_FILE")"
done

# --- Main loop: watch for new .queued files ---
inotifywait -m -e moved_to --format "%f" "$WATCH_DIR" | while read -r FILE; do
    process_file "$FILE"
    cleanup_old_files
done
