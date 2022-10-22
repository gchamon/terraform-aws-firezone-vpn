#!/usr/bin/env bash
exec > >(tee /var/log/user-data.log) 2>&1
set -eu

%{ if enable-cloudwatch-metrics ~}
# install and configure cloudwatch agent
sudo yum install --assumeyes amazon-cloudwatch-agent jq
cat <<-EOF > /opt/aws/amazon-cloudwatch-agent/bin/config.json
{
  "metrics": {
    "append_dimensions": {
      "AutoScalingGroupName": "\$${aws:AutoScalingGroupName}",
      "InstanceId": "\$${aws:InstanceId}"
    },
    "metrics_collected": {
      "mem": {
        "measurement": [
          "mem_used_percent"
        ],
        "metrics_collection_interval": 30
      },
      "swap": {
        "measurement": [
          "swap_used_percent",
          "swap_free"
        ],
        "metrics_collection_interval": 30
      },
      "disk": {
        "measurement": [
          "disk_used_percent"
        ],
        "metrics_collection_interval": 30,
        "resources": [
          "/"
        ]
      }
    }
  }
}
EOF
/opt/aws/amazon-cloudwatch-agent/bin/amazon-cloudwatch-agent-ctl \
  -a fetch-config \
  -m ec2 \
  -c file:/opt/aws/amazon-cloudwatch-agent/bin/config.json \
  -s

%{ endif ~}
function log {
  echo "--[$(date '+%Y-%m-%d %H:%M:%S')] $1"
}

log "STARTING USER-DATA"

# install docker and pull image
log "INSTALLING DOCKER"
yum install -y docker
systemctl enable docker.service
systemctl start docker.service
gpasswd -a ec2-user docker

log "INSTALLING DOCKER-COMPOSE"
DOCKER_CONFIG='/usr/local/lib/docker'
mkdir -p $DOCKER_CONFIG/cli-plugins
curl -SL https://github.com/docker/compose/releases/download/v2.12.1/docker-compose-linux-x86_64 -o $DOCKER_CONFIG/cli-plugins/docker-compose
chmod +x $DOCKER_CONFIG/cli-plugins/docker-compose
docker compose version

%{ if is_ecr_docker_image ~}
# authenticate to aws ecr
log "AUTHENTICATING TO AWS ECR"
aws ecr get-login-password --region ${aws_region} | docker login --username AWS --password-stdin ${aws_account_id}.dkr.ecr.${aws_region}.amazonaws.com
%{ endif ~}

# update instance ip
log "UPDATING INSTANCE IP"
export INSTANCE_ID=$(curl -s http://169.254.169.254/latest/meta-data/instance-id)
export REGION=$(curl -fsq http://169.254.169.254/latest/meta-data/placement/availability-zone | sed 's/[a-z]$//')

# If the association succeeds, the EIP is available and there is no main node. This becomes the main node in this case.
EPI_ASSOCIATION_ID="$(aws --region $REGION ec2 associate-address --allocation-id ${eip_id} --instance-id $INSTANCE_ID | jq -r '.AssociationId')"

# restore backup if exists
BACKUP_FILE='wireguard.tar.gz'
BACKUP_EXISTS="$(aws s3api head-object --bucket ${wireguard_backup_bucket_name} --key "$BACKUP_FILE" 2>&1 | grep -c LastModified)" || true
if [[ "$BACKUP_EXISTS" != "0" ]]; then
  log "RESTORING BACKUP"
  mkdir -p /data
  aws s3 cp s3://${wireguard_backup_bucket_name}/"$BACKUP_FILE" /tmp
  tar -xzvf /tmp/"$BACKUP_FILE" --directory /data
else
  echo "!! NO BACKUP PRESENT. STARTING FRESH"
fi

# sets cronjob routines for main or redundant node
log "SETTING CRONJOB ROUTINE"
if [[ "$EPI_ASSOCIATION_ID" != "null" ]]; then
  echo "This is the main node"
  CRON_FILE=/etc/cron.hourly/backup_wireguard
  cat <<EOF >>"$CRON_FILE"
#!/bin/sh
set -euo pipefail

rm -rf /tmp/"$BACKUP_FILE"
tar -czvf /tmp/"$BACKUP_FILE" --directory /data .
aws s3 cp /tmp/"$BACKUP_FILE" s3://${wireguard_backup_bucket_name}
rm -rf /tmp/"$BACKUP_FILE"
EOF
else
  echo "This is a redundant node"
  CRON_FILE=/etc/cron.hourly/pull_wireguard_backup
  cat <<EOF >>"$CRON_FILE"
#!/bin/sh
set -euo pipefail

rm -rf /tmp/"$BACKUP_FILE"
rm -rf /tmp/wireguard-data
aws s3 cp s3://${wireguard_backup_bucket_name}/"$BACKUP_FILE"  /tmp
tar -xzvf /tmp/"$BACKUP_FILE" --directory /tmp/wireguard-data
docker compose -f /data/docker-compose.yml down
rsync -va /tmp/wireguard-data /data
docker compose -f /data/docker-compose.yml up -d
rm -rf /tmp/wireguard-data
rm -rf /tmp/"$BACKUP_FILE"
EOF
fi
chmod +x "$CRON_FILE"

mkdir /data

# add configs
if ! [ -f /data/.env.gen ]; then
  cat <<EOF >/data/.env.gen
GUARDIAN_SECRET_KEY=$(openssl rand -base64 48)
SECRET_KEY_BASE=$(openssl rand -base64 48)
LIVE_VIEW_SIGNING_SALT=$(openssl rand -base64 24)
COOKIE_SIGNING_SALT=$(openssl rand -base64 6)
COOKIE_ENCRYPTION_SALT=$(openssl rand -base64 6)
DATABASE_ENCRYPTION_KEY=$(openssl rand -base64 32)
DATABASE_PASSWORD=$(openssl rand -base64 12)
EOF
fi

cat <<EOF >/data/.env.static
FZ_INSTALL_DIR=/data
EXTERNAL_URL=${firezone_external_url}
WIREGUARD_ENDPOINT=${wireguard_endpoint}
ADMIN_EMAIL=${admin_user_email}
DEFAULT_ADMIN_PASSWORD=${admin_password}
UID=1000
GID=1000

%{ for environment_variable_key, environment_variable_value in firezone_environment_variables }
${environment_variable_key}=${environment_variable_value}
%{ endfor ~}

EOF

cat /data/.env.static /data/.env.gen > /data/.env

cat <<EOF >/data/docker-compose.yml
x-deploy: &default-deploy
  restart_policy:
    condition: on-failure
    delay: 5s
    max_attempts: 3
    window: 120s
  update_config:
    order: start-first

version: '3.7'

services:
  caddy:
    image: caddy:2
    volumes:
      - $${FZ_INSTALL_DIR:-.}/caddy:/data/caddy
    ports:
      - 80:80
      - 443:443
    command: caddy reverse-proxy --to firezone:13000 --from $${EXTERNAL_URL:?err} $${CADDY_OPTS}
    deploy:
      <<: *default-deploy

  firezone:
    image: ${firezone_docker_image}
    ports:
      - 51820:51820/udp
    env_file:
      # This should contain a list of env vars for configuring Firezone.
      # See https://docs.firezone.dev/reference/env-vars for more info.
      - $${FZ_INSTALL_DIR:-.}/.env
    volumes:
      # IMPORTANT: Persists WireGuard private key and other data. If
      # /var/firezone/private_key exists when Firezone starts, it is
      # used as the WireGuard private. Otherwise, one is generated.
      - $${FZ_INSTALL_DIR:-.}/firezone:/var/firezone
    cap_add:
      # Needed for WireGuard and firewall support.
      - NET_ADMIN
      - SYS_MODULE
    sysctls:
      # Needed for masquerading and NAT.
      - net.ipv6.conf.all.disable_ipv6=0
      - net.ipv4.ip_forward=1
      - net.ipv6.conf.all.forwarding=1
    depends_on:
      - postgres
    deploy:
      <<: *default-deploy

  postgres:
    image: postgres:15
    volumes:
      - $${FZ_INSTALL_DIR:-.}/postgres:/var/lib/postgresql/data
    environment:
      POSTGRES_DB: $${DATABASE_NAME:-firezone}
      POSTGRES_USER: $${DATABASE_USER:-postgres}
      POSTGRES_PASSWORD: $${DATABASE_PASSWORD:?err}
    deploy:
      <<: *default-deploy
      update_config:
        order: stop-first

EOF

docker compose -f /data/docker-compose.yml up -d

log "ENDING USER-DATA"
