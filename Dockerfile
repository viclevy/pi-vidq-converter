FROM debian:bookworm-slim

# Install required dependencies in a single layer
RUN apt-get update && \
    apt-get upgrade -y && \
    apt-get install -y --no-install-recommends inotify-tools ffmpeg && \
    apt-get clean && \
    rm -rf /var/lib/apt/lists/*

WORKDIR /app

COPY convert_queued_files.sh /app/convert_queued_files.sh
RUN chmod +x /app/convert_queued_files.sh

CMD ["/app/convert_queued_files.sh"]

