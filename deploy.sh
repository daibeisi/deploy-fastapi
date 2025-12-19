#!/bin/bash

# ============================================
# FastAPI 应用部署脚本
# 支持 Docker Compose 优雅重启部署
# ============================================

set -e  # 遇到错误立即退出

# --- 配置变量 ---
APP_NAME="fastapi-cicd-app"
IMAGE_NAME="fastapi-cicd-app"
TAG=$(date +%Y%m%d%H%M%S)  # 时间戳标签，方便回滚
COMPOSE_FILE="docker-compose.yml"
HEALTH_CHECK_URL="http://localhost:8000/health"
MAX_RETRIES=30  # 健康检查最大重试次数
RETRY_INTERVAL=2  # 重试间隔（秒）

# 颜色输出
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

# 日志函数
log_info() {
    echo -e "${BLUE}[INFO]${NC} $1"
}

log_success() {
    echo -e "${GREEN}[SUCCESS]${NC} $1"
}

log_warning() {
    echo -e "${YELLOW}[WARNING]${NC} $1"
}

log_error() {
    echo -e "${RED}[ERROR]${NC} $1"
}

# 显示部署信息
show_banner() {
    echo "============================================"
    echo "  FastAPI 应用部署脚本"
    echo "  应用名称: $APP_NAME"
    echo "  镜像标签: $TAG"
    echo "  部署时间: $(date '+%Y-%m-%d %H:%M:%S')"
    echo "============================================"
}

# 检查 Docker 和 Docker Compose 是否安装
check_dependencies() {
    log_info "检查依赖..."
    
    if ! command -v docker &> /dev/null; then
        log_error "Docker 未安装，请先安装 Docker"
        exit 1
    fi
    
    if ! command -v docker-compose &> /dev/null && ! docker compose version &> /dev/null; then
        log_error "Docker Compose 未安装，请先安装 Docker Compose"
        exit 1
    fi
    
    log_success "依赖检查通过"
}

# 拉取最新代码（如果在 CI/CD 环境中，Jenkins 已经拉取了）
pull_code() {
    if [ -d ".git" ]; then
        log_info "拉取最新代码..."
        git pull origin main || log_warning "代码拉取失败，继续使用当前代码"
    else
        log_warning "非 Git 仓库，跳过代码拉取"
    fi
}

# 构建 Docker 镜像
build_image() {
    log_info "构建 Docker 镜像: $IMAGE_NAME:$TAG ..."
    
    docker build -t $IMAGE_NAME:$TAG . || {
        log_error "镜像构建失败"
        exit 1
    }
    
    # 打上 latest 标签
    docker tag $IMAGE_NAME:$TAG $IMAGE_NAME:latest
    log_success "镜像构建成功"
}

# 推送镜像到远程仓库（可选）
push_image() {
    if [ -n "$DOCKER_REGISTRY" ]; then
        log_info "推送镜像到仓库: $DOCKER_REGISTRY ..."
        docker tag $IMAGE_NAME:$TAG $DOCKER_REGISTRY/$IMAGE_NAME:$TAG
        docker tag $IMAGE_NAME:$TAG $DOCKER_REGISTRY/$IMAGE_NAME:latest
        docker push $DOCKER_REGISTRY/$IMAGE_NAME:$TAG
        docker push $DOCKER_REGISTRY/$IMAGE_NAME:latest
        log_success "镜像推送成功"
    else
        log_info "未配置镜像仓库，跳过推送"
    fi
}

# 使用 Docker Compose 部署（优雅重启）
deploy_with_compose() {
    log_info "使用 Docker Compose 部署应用..."
    
    # 检查 compose 文件是否存在
    if [ ! -f "$COMPOSE_FILE" ]; then
        log_error "找不到 $COMPOSE_FILE 文件"
        exit 1
    fi
    
    # 使用 docker compose 或 docker-compose
    if docker compose version &> /dev/null; then
        COMPOSE_CMD="docker compose"
    else
        COMPOSE_CMD="docker-compose"
    fi
    
    # 停止并重建服务（优雅重启）
    log_info "启动新容器..."
    $COMPOSE_CMD up -d --build --remove-orphans || {
        log_error "容器启动失败"
        exit 1
    }
    
    log_success "容器已启动"
}

# 健康检查
health_check() {
    log_info "执行健康检查..."
    
    local retry_count=0
    
    while [ $retry_count -lt $MAX_RETRIES ]; do
        if curl -f -s $HEALTH_CHECK_URL > /dev/null 2>&1; then
            log_success "健康检查通过 ✓"
            return 0
        fi
        
        retry_count=$((retry_count + 1))
        log_warning "健康检查未通过，重试 ($retry_count/$MAX_RETRIES)..."
        sleep $RETRY_INTERVAL
    done
    
    log_error "健康检查失败，服务可能未正常启动"
    log_info "查看容器日志: docker logs $APP_NAME"
    return 1
}

# 显示部署结果
show_result() {
    echo ""
    echo "============================================"
    log_success "部署完成！"
    echo "============================================"
    log_info "应用访问地址: http://localhost:8000"
    log_info "API 文档地址: http://localhost:8000/docs"
    log_info "健康检查地址: $HEALTH_CHECK_URL"
    echo ""
    log_info "常用命令:"
    echo "  - 查看容器状态: docker ps"
    echo "  - 查看应用日志: docker logs -f $APP_NAME"
    echo "  - 停止应用: docker-compose down"
    echo "  - 重启应用: docker-compose restart"
    echo "============================================"
}

# 回滚到上一个版本（发生错误时）
rollback() {
    log_error "部署失败，准备回滚..."
    
    # 这里可以实现回滚逻辑，比如切换到之前的镜像
    log_info "回滚逻辑待实现..."
    
    exit 1
}

# 清理旧镜像
cleanup_old_images() {
    log_info "清理悬空镜像..."
    docker image prune -f > /dev/null 2>&1 || true
    log_success "清理完成"
}

# 主流程
main() {
    show_banner
    
    # 检查依赖
    check_dependencies
    
    # 拉取代码（可选）
    # pull_code
    
    # 构建镜像
    build_image
    
    # 推送镜像（可选）
    # push_image
    
    # 部署应用
    deploy_with_compose
    
    # 健康检查
    if health_check; then
        show_result
        cleanup_old_images
        exit 0
    else
        rollback
    fi
}

# 捕获错误
trap 'log_error "脚本执行失败"; exit 1' ERR

# 执行主流程
main
