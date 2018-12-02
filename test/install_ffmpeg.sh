#!/bin/sh

add-apt-repository -y ppa:mc3man/trusty-media
apt-get -qq update
apt-get install -y ffmpeg
