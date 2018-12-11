FROM golang:1.11-alpine
MAINTAINER Preston Kutzner <shizzlecash@gmail.com>

ENV RESTIC_VERSION="0.9.3"
ENV RCLONE_VERSION="v1.45"
ENV DUMBINIT_VERSION="1.2.2"

# Backup options
ENV RESTIC_BACKUP_OPTIONS=""

# Enable cleanup cron job
ENV RESTIC_CLEANUP="true"

# Rclone options
# Base directory where rclone will look for its config
#  e.g. $XDG_CONFIG_HOME/rclone/rclone.conf
#ENV XDG_CONFIG_HOME="~/.config"

# Cleanup params
ENV RESTIC_CLEANUP_OPTIONS="--prune"

# Default interval times can be set in cron expression
# Fire at 03:15 every day
ENV CRON_BACKUP_EXPRESSION="0 * * * *"
# Fire at 15 minutes past the hour for hourly rotation
ENV CRON_CLEANUP_EXPRESSION="15 * * * *"

# Script and config
ADD ./target/start_cron.sh /go/bin
ADD ./target/supervisor_restic.ini /etc/supervisor.d/restic.ini
ADD ./target/restic-runner /go/bin

# Install the items
RUN apk update \
  && apk add bash bc ca-certificates coreutils fuse wget supervisor gnupg git unzip util-linux \
  && update-ca-certificates \
  && wget -qO /tmp/restic-${RESTIC_VERSION}.tar.gz "https://github.com/restic/restic/releases/download/v${RESTIC_VERSION}/restic-${RESTIC_VERSION}.tar.gz" \
  && wget -qO /tmp/rclone-${RCLONE_VERSION}-linux-amd64.zip "https://downloads.rclone.org/${RCLONE_VERSION}/rclone-${RCLONE_VERSION}-linux-amd64.zip" \
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
  && rm -rf /tmp/restic* /tmp/rclone* /var/cache/apk/* \
  && wget -qO /usr/local/bin/dumb-init "https://github.com/Yelp/dumb-init/releases/download/v${DUMBINIT_VERSION}/dumb-init_${DUMBINIT_VERSION}_amd64" \
  && chmod +x /usr/local/bin/dumb-init

# Start the process
#CMD supervisord -c /etc/supervisord.conf

ENTRYPOINT ["/usr/local/bin/dumb-init", "--"]
CMD ["supervisord", "-c", "/etc/supervisord.conf"]
