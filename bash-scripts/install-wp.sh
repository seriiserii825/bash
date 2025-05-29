#!/bin/bash -x

docker-compose run --rm wpcli core install \
  --url="http://localhost:8888" \
  --title="My Site" \
  --admin_user=admin \
  --admin_password=admin \
  --admin_email=admin@gmail.com \
  --skip-email
