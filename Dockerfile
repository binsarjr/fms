FROM frappe/build:v15 as base

USER root

# Untuk keperluan ssh dan tailscale, edit file keys.txt untuk menambang/mengurangi kunci ssh
COPY keys.txt /root/.ssh/authorized_keys

# Install cron, bzip2, gnupg2, sshd, tailscale, supervisor
RUN curl -fsSL https://pkgs.tailscale.com/stable/debian/bookworm.noarmor.gpg | tee /usr/share/keyrings/tailscale-archive-keyring.gpg >/dev/null \
    && curl -fsSL https://pkgs.tailscale.com/stable/debian/bookworm.tailscale-keyring.list | tee /etc/apt/sources.list.d/tailscale.list \
    && apt-get update \
    && apt-get install -y cron && which cron && \
    rm -rf /etc/cron.*/* \
    && apt-get install -y bzip2 \
    && apt-get install -y gnupg2 \
    && apt-get install -y rsync \
    && apt-get install -y openssh-server \
    && mkdir /var/run/sshd \
    && apt-get install -y tailscale && curl -fsSL https://tailscale.com/install.sh | sh \
    && apt-get install -y supervisor \
    && mkdir -p /root/.ssh \
    && chmod 600 /root/.ssh/authorized_keys \
    && chmod 700 /root/.ssh \
    && sed -i 's/#PermitRootLogin prohibit-password/PermitRootLogin yes/' /etc/ssh/sshd_config \
    && sed 's@session\s*required\s*pam_loginuid.so@session optional pam_loginuid.so@g' -i /etc/pam.d/sshd \
    && chown -R frappe:frappe /home/frappe

FROM base AS frappe

USER frappe

COPY motd.txt /etc/motd

ARG FRAPPE_BRANCH=version-15
ARG FRAPPE_PATH=https://github.com/frappe/frappe
# ARG ERPNEXT_REPO=https://github.com/frappe/erpnext
# ARG ERPNEXT_BRANCH=version-15
RUN bench init \
  --frappe-branch=${FRAPPE_BRANCH} \
  --frappe-path=${FRAPPE_PATH} \
  --no-procfile \
  --no-backups \
  --skip-redis-config-generation \
  --verbose \
  /home/frappe/frappe-bench && \
  cd /home/frappe/frappe-bench && \
  echo "{}" > sites/common_site_config.json


RUN touch /home/frappe/first_run
COPY prepare.sh /usr/local/bin/prepare.sh
COPY start-backend.sh /usr/local/bin/start-backend.sh

USER root

RUN echo "cat /etc/motd" >> ~/.bashrc \
    && chmod +x /usr/local/bin/prepare.sh \
    && chmod +x /usr/local/bin/start-backend.sh

WORKDIR /home/frappe/frappe-bench

VOLUME [ \
  "/home/frappe/frappe-bench/sites", \
  "/home/frappe/frappe-bench/sites/assets", \
  "/home/frappe/frappe-bench/logs" \
]

COPY supervisord.conf /etc/supervisor/conf.d/supervisord.conf

EXPOSE 22
EXPOSE 3000
EXPOSE 8000
EXPOSE 8080

CMD ["supervisord", "-n"]
