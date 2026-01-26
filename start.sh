#!/bin/bash

# create ./public/images directory if it doesn't exist
if [ ! -d "./public/images" ]; then
    mkdir -p ./public/images
    echo "Created directory: ./public/images"
else
    echo "Directory already exists: ./public/images"
fi

# start the application
npm start