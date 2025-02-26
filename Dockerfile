FROM xream/sub-store:latest

# 设置时区（如果需要）
ENV TIME_ZONE=Asia/Shanghai
RUN cp /usr/share/zoneinfo/$TIME_ZONE /etc/localtime && echo $TIME_ZONE > /etc/timezone

# 暴露前端服务端口（根据实际需要调整）
EXPOSE 3001

# 启动服务并运行定时任务调度
CMD ["sh", "-c", "\
  mkdir -p /opt/app/data && cd /opt/app/data && \
  (META_FOLDER=/opt/app/http-meta HOST=:: node /opt/app/http-meta.bundle.js > /opt/app/data/http-meta.log 2>&1 &) && \
  (SUB_STORE_BACKEND_API_HOST=:: SUB_STORE_FRONTEND_HOST=:: SUB_STORE_FRONTEND_PORT=3001 SUB_STORE_FRONTEND_PATH=/opt/app/frontend SUB_STORE_DATA_BASE_PATH=/opt/app/data node /opt/app/sub-store.bundle.js & \
  if [ -n \"$SUB_STORE_BACKEND_UPLOAD_CRON\" ]; then \
    node -e 'const cron = require(\"node-cron\"); cron.schedule(\"$SUB_STORE_BACKEND_UPLOAD_CRON\", () => { console.log(\"Executing scheduled task\"); process.exit(0); });' & \
  fi \
  ) \
"]
