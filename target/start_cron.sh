#!/bin/sh
set -e
echo "${CRON_BACKUP_EXPRESSION} supervisorctl start restic_backup" | crontab -
[ "$RESTIC_CLEANUP" = true ] && { crontab -l | { cat; echo "${CRON_CLEANUP_EXPRESSION} supervisorctl start restic_cleanup"; } | crontab -; }
/usr/sbin/crond -f

