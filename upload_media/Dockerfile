# 使用官方的 Python 镜像作为基础镜像
FROM python:3.12.3-slim

# 设置工作目录
WORKDIR /app

# 将当前目录的内容复制到工作目录
COPY . /app

# 设置时区环境变量并安装 tzdata
ENV TZ=Asia/Shanghai
RUN apt-get update && apt-get install -y tzdata

# 安装所需的 Python 包
RUN pip install --no-cache-dir fastapi uvicorn[standard] requests pydantic python-dotenv

# 暴露默认应用程序运行的端口（可以根据需要更改）
EXPOSE 8000

# 启动 FastAPI 应用程序，端口由环境变量指定
CMD ["sh", "-c", "uvicorn main:app --host 0.0.0.0 --port ${FASTAPI_PORT:-8000}"]
