# Pi Camera Recording Service — Video Conversion Pipeline

A lightweight, Dockerized service that automatically converts raw video files from a Raspberry Pi camera into MP4 format using ffmpeg.

## How It Works

1. An external process (e.g. a Pi camera recording service) writes raw video files and moves them into the `recordings/` directory with a `.queued` extension.
2. This service watches that directory for new `.queued` files using `inotifywait` (filesystem events).
3. When a `.queued` file appears, it is converted to MP4 (H.264 video + AAC audio) via ffmpeg, then the original is deleted.

The service uses a filesystem-based queue — no database or message broker is needed. The `.queued` files **are** the queue.

## Automatic Cleanup

- **Old files**: MP4 files older than 90 days (~3 months) are automatically deleted on startup and after each new conversion. This prevents the recordings directory from growing indefinitely.
- **Small files**: Converted MP4 files smaller than 600KB are deleted after each conversion, as they are likely corrupt or trivially short.

## Build

```bash
docker build -t queued_file_conversion:latest .
```

## Run

```bash
docker run -d \
  --name queued_file_conversion \
  --restart unless-stopped \
  -v /opt/picamerarecordingservice/recordings:/app/recordings \
  queued_file_conversion:latest
```

The bind mount maps the host `recordings/` directory into the container at `/app/recordings`.

## Configuration

Edit the variables at the top of `convert_queued_files.sh`:

| Variable | Default | Description |
|---|---|---|
| `WATCH_DIR` | `/app/recordings` | Directory to monitor for `.queued` files |
| `MAX_AGE_DAYS` | `90` | Delete MP4 files older than this many days |
| `MIN_FILE_SIZE` | `600k` | Delete MP4 files smaller than this after conversion |

Rebuild the Docker image after making changes.

## Requirements

- Docker
- The upstream recording process must atomically **move** (not copy/write) files into the recordings directory with a `.queued` extension.
