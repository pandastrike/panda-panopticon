# Start with base image.
FROM ubuntu:latest
MAINTAINER David Harper "david@pandastrike.com"

# Add the necessary technologies to assemble this app.
RUN apt-get update
RUN apt-get install git
RUN apt-get install nodejs
RUN apt-get install npm

# Pull the app from its git repository and place it in this image.
RUN mkdir var/panda_panopticon
RUN cd var/panda_panopticon
RUN git init
RUN git clone https://github.com/pandastrike/panda-panopticon.git
