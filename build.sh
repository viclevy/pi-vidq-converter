
docker container stop convert_queued_files
docker container rm convert_queued_files
docker build . --tag queued_file_conversion:latest

docker run -it -d --name convert_queued_files --restart unless-stopped -v /opt/picamerarecordingservice/recordings:/app/recordings queued_file_conversion:latest


