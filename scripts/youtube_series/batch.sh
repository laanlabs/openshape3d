#!/bin/zsh
# Record + compose several project tutorials in a row: batch.sh brick mug …
export DEVELOPER_DIR=/Applications/Xcode.app/Contents/Developer
export OS3D_VIDEO_OUT=${OS3D_VIDEO_OUT:-/Users/thelodgestudio/projects/openshape3d/marketing/youtube}
cd "$(dirname "$0")"
for v in "$@"; do
  echo "=== $v $(date +%H:%M:%S)"
  python3 project_tutorial.py $v > take-$v.log 2>&1 && echo "ok $v" || echo "FAILED $v"
  grep -E "missed|save sheet|failed:|Traceback" take-$v.log | head -5
done
echo "=== batch done $(date +%H:%M:%S)"
