FROM alpine:3.21

RUN apk add --no-cache bash ffmpeg inotify-tools

WORKDIR /app

COPY convert_queued_files.sh /app/convert_queued_files.sh
RUN chmod +x /app/convert_queued_files.sh

CMD ["/app/convert_queued_files.sh"]

