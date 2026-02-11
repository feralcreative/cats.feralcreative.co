#!/bin/sh
# Substitute environment variables in mediamtx.yml using sed
sed -e "s/\${CAMERA_USER}/${CAMERA_USER}/g" \
    -e "s/\${CAMERA_PASS}/${CAMERA_PASS}/g" \
    /mediamtx.yml.template > /mediamtx.yml

# Start mediamtx
exec /mediamtx

