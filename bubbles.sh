#!/bin/bash

source /etc/profile.d/chruby.sh
cd /home/bubbles/gltail
ruby restart_bubbles.rb >> bubbles.log 2>&1
