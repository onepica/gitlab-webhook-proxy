# gitlab-webhook-proxy
Proxy server for GitLab Webhooks

## Installation
1. Copy [`run.dist.sh`](run.dist.sh) to `run.sh` and make sure all stub data is updated inside copied file.
2. Update [docker-compose.yml](docker-compose.yml) file if needed.
3. Wake up the container by command `docker-compose up -d` from the project directory.
