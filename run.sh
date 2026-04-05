
docker run -it --name convert_queued_files --restart unless-stopped -v /opt/picamerarecordingservice/recordings:/app/recordings queued_file_conversion:latest

