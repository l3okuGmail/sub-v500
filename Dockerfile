FROM alpine

WORKDIR /opt/app

RUN apk add --no-cache nodejs curl tzdata unzip jq

ENV TIME_ZONE=Asia/Shanghai

RUN cp /usr/share/zoneinfo/$TIME_ZONE /etc/localtime && echo $TIME_ZONE > /etc/timezone

# 添加 GitHub token 来避免频繁退出
ARG GITHUB_TOKEN
RUN curl -L -H "Authorization: token ${GITHUB_TOKEN}" "https://github.com/sub-store-org/Sub-Store/releases/latest/download/sub-store.bundle.js" -o /opt/app/sub-store.bundle.js

# 使用 GitHub API 获取最新版本的下载链接
RUN version=$(curl -s https://api.github.com/repos/sub-store-org/Sub-Store/releases/latest | jq -r .tag_name) && \
    curl -L "https://github.com/sub-store-org/Sub-Store/releases/download/$version/sub-store.bundle.js" -o /opt/app/sub-store.bundle.js

# 继续下载其他文件
COPY dist.zip /opt/app/dist.zip
COPY http-meta.bundle.js /opt/app/http-meta.bundle.js
COPY tpl.yaml /opt/app/http-meta/tpl.yaml

RUN unzip dist.zip; mv dist frontend; rm dist.zip

RUN version_mihomo=$(curl -s -L --connect-timeout 5 --max-time 10 --retry 2 --retry-delay 0 --retry-max-time 20 'https://github.com/MetaCubeX/mihomo/releases/download/Prerelease-Alpha/version.txt') && \
  arch=$(arch | sed s/aarch64/arm64/ | sed s/x86_64/amd64-compatible/) && \
  url="https://github.com/MetaCubeX/mihomo/releases/download/Prerelease-Alpha/mihomo-linux-$arch-$version_mihomo.gz" && \
  curl -s -L --connect-timeout 5 --max-time 10 --retry 2 --retry-delay 0 --retry-max-time 20 "$url" -o /opt/app/http-meta/http-meta.gz && \
  gunzip /opt/app/http-meta/http-meta.gz && \
  rm -rf /opt/app/http-meta/http-meta.gz

RUN chmod 777 -R /opt/app

CMD mkdir -p /opt/app/data; cd /opt/app/data; \
  META_FOLDER=/opt/app/http-meta HOST=:: node /opt/app/http-meta.bundle.js > /opt/app/data/http-meta.log 2>&1 & echo "HTTP-META is running..."; \
  SUB_STORE_BACKEND_API_HOST=:: SUB_STORE_FRONTEND_HOST=:: SUB_STORE_FRONTEND_PORT=3001 SUB_STORE_FRONTEND_PATH=/opt/app/frontend SUB_STORE_DATA_BASE_PATH=/opt/app/data node /opt/app/sub-store.bundle.js
