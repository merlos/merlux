#!/bin/sh

REPO='merlos'

# Version YYYY-MM-DD
VERSION=$(date +'%Y-%m-%d')

# Build for amd64 
docker build --platform linux/amd64 -t $REPO/cloudfared:latest -t $REPO/cloudfared:$VERSION .

# Push to repository
docker push $REPO/cloudfared:latest
docker push $REPO/cloudfared:$VERSION