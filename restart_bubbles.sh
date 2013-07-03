#! /bin/sh
cd /Users/bheeshmar/gltail/
git pull -r
killall gltail
bin/gltail bloomfire.yaml
