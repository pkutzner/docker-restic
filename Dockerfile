FROM golang:1.10.3-alpine
MAINTAINER Preston Kutzner <shizzlecash@gmail.com>

ENV RESTIC_VERSION="0.9.1"
ENV RCLONE_VERSION="v1.42"

# Backup options
ENV RESTIC_BACKUP_OPTIONS=""

# Rclone options
# Base directory where rclone will look for its config
#  e.g. $XDG_CONFIG_HOME/rclone/rclone.conf
#ENV XDG_CONFIG_HOME="~/.config"

# Cleanup params
ENV RESTIC_CLEANUP_KEEP_DAILY=7
ENV RESTIC_CLEANUP_KEEP_WEEKLY=5
ENV RESTIC_CLEANUP_KEEP_MONTHLY=12
ENV RESTIC_CLEANUP_KEEP_YEARLY=75
ENV RESTIC_CLEANUP_OPTIONS="--prune"

# Default interval times can be set in cron expression
# Fire at 03:15 every day
ENV CRON_BACKUP_EXPRESSION="15   3  *   *   *"
# Fire at 00:15 on the first day of every month
ENV CRON_CLEANUP_EXPRESSION="15  0  0   *   *"

# Script and config
ADD ./target/start_cron.sh /go/bin
ADD ./target/supervisor_restic.ini /etc/supervisor.d/restic.ini
ADD ./target/restic-runner /go/bin

# Install the items
RUN apk update \
  && apk add bash bc ca-certificates coreutils wget supervisor gnupg unzip \
  && update-ca-certificates \
  && wget -O /tmp/restic-${RESTIC_VERSION}.tar.gz "https://github.com/restic/restic/releases/download/v${RESTIC_VERSION}/restic-${RESTIC_VERSION}.tar.gz" \
  && wget -O /tmp/rclone-${RCLONE_VERSION}-linux-amd64.zip "https://downloads.rclone.org/${RCLONE_VERSION}/rclone-${RCLONE_VERSION}-linux-amd64.zip" \
  && tar -xf /tmp/restic-${RESTIC_VERSION}.tar.gz -C /tmp/ \
  && cd /tmp/restic-${RESTIC_VERSION} \
  && go run build.go \
  && mv restic /go/bin/restic \
  && cd /tmp \
  && unzip rclone-${RCLONE_VERSION}-linux-amd64.zip \
  && mv /tmp/rclone-${RCLONE_VERSION}-linux-amd64/rclone /go/bin/rclone \
  && chmod +x /go/bin/start_cron.sh \
  && cd / \
  && mkdir -p /var/log/supervisor \
  && rm -rf /tmp/restic* /tmp/rclone* /var/cache/apk/*

# Start the process
CMD supervisord -c /etc/supervisord.conf

