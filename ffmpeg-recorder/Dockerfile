FROM alpine:latest

RUN apk --no-cache add ffmpeg curl tzdata font-noto

COPY run.sh /usr/local/bin/run.sh
RUN chmod +x /usr/local/bin/run.sh

RUN mkdir -p /recordings
VOLUME ["/recordings"]

CMD ["/usr/local/bin/run.sh"]
