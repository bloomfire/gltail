#! /bin/bash --login
killall ruby
cd /Users/bheeshmar/gltail/ && git pull -r
source /Users/bheeshmar/gltail/.rvmrc
cd /Users/bheeshmar/gltail/ && ./bin/gl_tail bloomfire.yaml
