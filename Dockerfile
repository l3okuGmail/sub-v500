FROM alpine

WORKDIR /opt/app

# 安装所需的工具，包括 nodejs, curl, tzdata, cronie, unzip 等
RUN apk add --no-cache nodejs curl tzdata cronie unzip

# 设置时区
ENV TIME_ZONE=Asia/Shanghai
RUN cp /usr/share/zoneinfo/$TIME_ZONE /etc/localtime && echo $TIME_ZONE > /etc/timezone

# 添加 sub-store 和相关的资源
ADD https://github.com/sub-store-org/Sub-Store/releases/latest/download/sub-store.bundle.js /opt/app/sub-store.bundle.js
ADD https://github.com/sub-store-org/Sub-Store-Front-End/releases/latest/download/dist.zip /opt/app/dist.zip
ADD https://github.com/xream/http-meta/releases/latest/download/http-meta.bundle.js /opt/app/http-meta.bundle.js
ADD https://github.com/xream/http-meta/releases/latest/download/tpl.yaml /opt/app/http-meta/tpl.yaml

# 解压前端资源
RUN unzip dist.zip; mv dist frontend; rm dist.zip

# 获取最新的 http-meta 资源
RUN version=$(curl -s -L --connect-timeout 5 --max-time 10 --retry 2 --retry-delay 0 --retry-max-time 20 'https://github.com/MetaCubeX/mihomo/releases/download/Prerelease-Alpha/version.txt') && \
  arch=$(arch | sed s/aarch64/arm64/ | sed s/x86_64/amd64-compatible/) && \
  url="https://github.com/MetaCubeX/mihomo/releases/download/Prerelease-Alpha/mihomo-linux-$arch-$version.gz" && \
  curl -s -L --connect-timeout 5 --max-time 10 --retry 2 --retry-delay 0 --retry-max-time 20 "$url" -o /opt/app/http-meta/http-meta.gz && \
  gunzip /opt/app/http-meta/http-meta.gz && \
  rm -rf /opt/app/http-meta/http-meta.gz

# 给予文件适当权限
RUN chmod 777 -R /opt/app

# 创建更新脚本 update.sh
RUN echo '#!/bin/sh\n\
curl -s -L --connect-timeout 5 --max-time 10 --retry 2 --retry-delay 0 --retry-max-time 20 https://github.com/sub-store-org/Sub-Store/releases/latest/download/sub-store.bundle.js -o /opt/app/sub-store.bundle.js\n\
if [ $? -eq 0 ]; then\n\
  echo "sub-store.bundle.js updated successfully."\n\
else\n\
  echo "Failed to update sub-store.bundle.js."\n\
fi' > /opt/app/update.sh && chmod +x /opt/app/update.sh

# 添加 crontab 文件，设置定时任务为每天凌晨12点05分
RUN echo "5 0 * * * /opt/app/update.sh" > /etc/crontabs/root

# 设置 cron 服务后台运行并启动应用
CMD crond && mkdir -p /opt/app/data && cd /opt/app/data && \
  META_FOLDER=/opt/app/http-meta HOST=:: node /opt/app/http-meta.bundle.js > /opt/app/data/http-meta.log 2>&1 & \
  echo "HTTP-META is running..." && \
  SUB_STORE_BACKEND_API_HOST=:: SUB_STORE_FRONTEND_HOST=:: SUB_STORE_FRONTEND_PORT=3001 SUB_STORE_FRONTEND_PATH=/opt/app/frontend SUB_STORE_DATA_BASE_PATH=/opt/app/data node /opt/app/sub-store.bundle.js
