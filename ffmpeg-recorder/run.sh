#!/bin/sh
set -e

: "${SNAPSHOT_URL}"
: "${FPS:=10}"
: "${CLIP_LENGTH:=60}"
: "${RETENTION_DAYS:=7}"
: "${TZ:=Etc/UTC}"
: "${QUALITY:=23}"

echo ">>> Using SNAPSHOT_URL:   $SNAPSHOT_URL"
echo ">>> Using FPS:            $FPS"
echo ">>> Using CLIP_LENGTH:    $CLIP_LENGTH seconds"
echo ">>> Using RETENTION_DAYS: $RETENTION_DAYS days"
echo ">>> Using TZ:             $TZ"
echo ">>> Using QUALITY:        $QUALITY"

ln -snf "/usr/share/zoneinfo/$TZ" /etc/localtime
echo "$TZ" > /etc/timezone

mkdir -p /recordings

( # Background job to remove old clips
  while true
  do
    echo ">>> [Cleanup job] Removing files older than $RETENTION_DAYS days..."
    find /recordings -type f -mtime +$RETENTION_DAYS -exec rm -f {} \; || true
    sleep 86400
  done
) &

sleep_interval=$(awk "BEGIN { if ($FPS>0) printf \"%.4f\", 1/$FPS; else printf \"0.2\";}")

( 
  while true
  do
    # Poll the snapshot
    curl -s "$SNAPSHOT_URL" || echo "Failed to fetch snapshot"
    # Optional short sleep if you don't want to hammer the server
    # sleep 0.1 
    # I would like to hammer the server.
  done
) | ffmpeg -hide_banner -loglevel info \
    -f image2pipe \
    -use_wallclock_as_timestamps 1 \
    -vsync 2 \
    -i pipe:0 \
    -vf "drawtext=fontfile=/usr/share/fonts/TTF/DejaVuSans.ttf:
         text='%{localtime}':
         x=7:y=7:fontcolor=white@0.8:box=1:boxcolor=black@0.5" \
    -c:v libx264 -preset veryfast -pix_fmt yuv420p \
    -crf "$QUALITY" \
    -f segment -segment_time "$CLIP_LENGTH" \
    -reset_timestamps 1 -strftime 1 \
    "/recordings/%Y-%m-%d_%H-%M-%S.mp4"

