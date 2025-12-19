# ===========================
# 第一阶段: 构建阶段
# ===========================
FROM python:3.11-slim as builder

# 设置工作目录
WORKDIR /build

# 安装系统依赖和 uv
RUN apt-get update && apt-get install -y --no-install-recommends \
    curl \
    && curl -LsSf https://astral.sh/uv/install.sh | sh \
    && rm -rf /var/lib/apt/lists/*

# 确保 uv 在 PATH 中
ENV PATH="/root/.cargo/bin:$PATH"

# 复制项目配置文件
COPY pyproject.toml uv.lock* ./

# 安装依赖（不包括开发依赖）
RUN uv sync --no-dev --frozen

# ===========================
# 第二阶段: 运行阶段
# ===========================
FROM python:3.11-slim

# 设置环境变量
ENV PYTHONUNBUFFERED=1 \
    PYTHONDONTWRITEBYTECODE=1 \
    APP_ENV=production

# 创建非 root 用户
RUN useradd -m -u 1000 appuser

# 设置工作目录
WORKDIR /app

# 从构建阶段复制虚拟环境
COPY --from=builder /build/.venv /app/.venv

# 复制应用代码
COPY ./app /app

# 修改文件所有者
RUN chown -R appuser:appuser /app

# 切换到非 root 用户
USER appuser

# 设置 PATH 使用虚拟环境
ENV PATH="/app/.venv/bin:$PATH"

# 暴露端口
EXPOSE 8000

# 健康检查
HEALTHCHECK --interval=30s --timeout=10s --start-period=40s --retries=3 \
    CMD python -c "import urllib.request; urllib.request.urlopen('http://localhost:8000/health')" || exit 1

# 启动命令
CMD ["uvicorn", "main:app", "--host", "0.0.0.0", "--port", "8000", "--workers", "2"]
