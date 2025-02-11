FROM alpine

WORKDIR /opt/app

RUN apk add --no-cache nodejs curl tzdata unzip

ENV TIME_ZONE=Asia/Shanghai 

RUN cp /usr/share/zoneinfo/$TIME_ZONE /etc/localtime && echo $TIME_ZONE > /etc/timezone

ARG CACHEBUST=1

RUN curl -L "https://github.com/sub-store-org/Sub-Store/releases/latest/download/sub-store.bundle.js?cachebust=${CACHEBUST}" -o /opt/app/sub-store.bundle.js

ADD https://github.com/sub-store-org/Sub-Store-Front-End/releases/latest/download/dist.zip /opt/app/dist.zip

RUN unzip dist.zip; mv dist frontend; rm dist.zip

ADD https://github.com/xream/http-meta/releases/latest/download/http-meta.bundle.js /opt/app/http-meta.bundle.js

ADD https://github.com/xream/http-meta/releases/latest/download/tpl.yaml /opt/app/http-meta/tpl.yaml

RUN version=$(curl -s -L --connect-timeout 5 --max-time 10 --retry 2 --retry-delay 0 --retry-max-time 20 'https://github.com/MetaCubeX/mihomo/releases/download/Prerelease-Alpha/version.txt') && \
  arch=$(arch | sed s/aarch64/arm64/ | sed s/x86_64/amd64-compatible/) && \
  url="https://github.com/MetaCubeX/mihomo/releases/download/Prerelease-Alpha/mihomo-linux-$arch-$version.gz" && \
  curl -s -L --connect-timeout 5 --max-time 10 --retry 2 --retry-delay 0 --retry-max-time 20 "$url" -o /opt/app/http-meta/http-meta.gz && \
  gunzip /opt/app/http-meta/http-meta.gz && \
  rm -rf /opt/app/http-meta/http-meta.gz

RUN chmod 777 -R /opt/app

# 关键修改：强制会话持久化 + Cookie配置
CMD mkdir -p /opt/app/data; cd /opt/app/data; \
  META_FOLDER=/opt/app/http-meta HOST=:: node /opt/app/http-meta.bundle.js > /opt/app/data/http-meta.log 2>&1 & echo "HTTP-META is running..."; \
  SUB_STORE_BACKEND_API_HOST=:: \
  SUB_STORE_FRONTEND_HOST=:: \
  SUB_STORE_FRONTEND_PORT=3001 \
  SUB_STORE_FRONTEND_PATH=/opt/app/frontend \
  SUB_STORE_DATA_BASE_PATH=/opt/app/data \
  SESSION_MAX_AGE=2592000000 \        # 30天会话有效期（核心）
  SESSION_COOKIE_SECURE=false \       # 关闭Secure属性（适用于HTTP环境）
  SESSION_COOKIE_SAME_SITE=Lax \      # 避免跨域限制（根据实际情况调整）
  node /opt/app/sub-store.bundle.js
