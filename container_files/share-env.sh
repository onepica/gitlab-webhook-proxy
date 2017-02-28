#!/usr/bin/env bash
# Share env variables for SSH connections
if [ ! -f /etc/profile.d/shared-env.sh ]; then
  echo '# Copied env variables for SSH connections'>> /etc/profile.d/shared-env.sh
  printenv | sort | \
      grep -E '(MYSQL_|DOCROOT_OWNER_|CRONTAB_|APP_|ADMIN_|MAGE_)' | \
      sed -re 's|([^=]+).(.*)|export \1="\2"|g' >> /etc/profile.d/shared-env.sh
fi
