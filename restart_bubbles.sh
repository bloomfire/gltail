#! /bin/sh
cd /Users/bheeshmar/gltail/
git pull -r
killall ruby
./bin/gl_tail bloomfire.yaml
