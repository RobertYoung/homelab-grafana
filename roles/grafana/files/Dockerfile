FROM debian:12

RUN apt-get update && \
  apt-get install -y curl zip unzip less vim tar mosquitto-clients && \
  curl "https://awscli.amazonaws.com/awscli-exe-linux-x86_64.zip" -o "awscliv2.zip" && \
  unzip awscliv2.zip && \
  ./aws/install && \
  rm -rf awscliv2.zip aws

COPY backup.sh .

RUN chmod +x backup.sh

