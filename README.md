# FastAPI CI/CD 学习项目

> 一个完整的 FastAPI 项目，配备 Jenkins CI/CD 流水线，用于学习和实践持续集成与持续部署。

## 📋 项目特点

- ✅ **完整 CI/CD 流程**：代码提交到自动部署
- 🐳 **Docker 容器化**：多阶段构建
- 🚀 **优雅部署**：零停机部署 + 自动健康检查
- 🔍 **代码质量检查**：Flake8、Black、Bandit
- 🧪 **自动化测试**：Pytest + 覆盖率报告
- 📊 **严格质量门控**：测试失败阻止部署

## 🏗️ 项目结构

```
deploy-fastapi/
├── app/                   # 应用代码
├── tests/                 # 测试文件
├── scripts/               # 工具脚本
│   ├── pre-commit-check.ps1
│   └── pre-commit-check.sh
├── docs/                  # 文档
├── Dockerfile
├── docker-compose.yml
├── Jenkinsfile           # CI/CD 流水线
├── deploy.sh             # 部署脚本
└── requirements.txt
```

## 🚀 快速开始

### 1. 配置环境变量

```bash
cp .env.example .env
```

### 2. 启动应用

```bash
# 方式 A: Docker Compose（推荐）
docker-compose up -d --build

# 方式 B: 本地开发
python -m venv venv
venv\Scripts\activate  # Windows
pip install -r requirements.txt
cd app && python main.py
```

### 3. 访问应用

- 应用主页: http://localhost:8000
- API 文档: http://localhost:8000/docs
- 健康检查: http://localhost:8000/health

---

## 🚨 CI/CD 质量门控

| 检查项 | 失败时处理 | 是否阻断 |
|--------|-----------|---------|
| Flake8 | ❌ 构建失败 | ✅ 阻断 |
| Black | ⚠️ Unstable | ❌ 警告 |
| Bandit | ⚠️ Unstable | ❌ 警告 |
| Pytest | ❌ 构建失败 | ✅ 阻断 |
| Docker | ❌ 构建失败 | ✅ 阻断 |
| Health | ❌ 回滚 | ✅ 阻断 |

### 本地预检查（推荐）

```bash
# Windows
.\scripts\pre-commit-check.ps1

# Linux/Mac
./scripts/pre-commit-check.sh
```

📖 [详细处理文档](docs/CI-CD-FAILURE-HANDLING.md)

---

## 🔧 Jenkins 配置

### 1. 启动 Jenkins

```bash
docker run -d --name jenkins \
  -p 8080:8080 -p 50000:50000 \
  -v jenkins_home:/var/jenkins_home \
  -v /var/run/docker.sock:/var/run/docker.sock \
  jenkins/jenkins:lts
```

### 2. 创建 Pipeline

1. 访问 http://localhost:8080
2. 安装插件：Docker Pipeline、Git Plugin、Pipeline
3. 新建流水线项目，指向 Git 仓库
4. 指定 Jenkinsfile 路径

### 3. 配置 Webhook（可选）

在 Git 仓库设置中添加：
```
http://jenkins-url:8080/github-webhook/
```

---

## 🔄 Jenkinsfile 流程

```
📦 环境准备 → 检出代码
    ↓
🔍 代码检查 → Flake8, Black, Bandit (并行)
    ↓
🧪 单元测试 → Pytest + 覆盖率
    ↓
🏗️ 构建镜像 → Docker 多阶段构建
    ↓
🔐 镜像扫描 → 安全漏洞扫描
    ↓
📤 推送镜像 → 推送到镜像仓库
    ↓
🚀 部署应用 → 执行 deploy.sh
    ↓
✅ 健康检查 → 验证服务正常
    ↓
🧹 清理 → 清理旧资源
```

---

## 📜 部署脚本

### deploy.sh 功能

- ✅ 自动构建 Docker 镜像
- ✅ Docker Compose 优雅重启
- ✅ 自动健康检查（最多重试 30 次）
- ✅ 失败自动回滚
- ✅ 彩色日志输出

### 手动部署

```bash
chmod +x deploy.sh
./deploy.sh
```

---

## 🔍 代码质量检查

```bash
# Flake8 - 代码规范
flake8 app/

# Black - 代码格式化
black app/

# Bandit - 安全扫描
bandit -r app/

# Pytest - 运行测试
pytest tests/ --cov=app
```

---

## 🐳 常用命令

```bash
# 查看容器状态
docker ps

# 查看日志
docker logs -f fastapi-cicd-app
docker-compose logs -f

# 重启应用
docker-compose restart

# 停止应用
docker-compose down

# 清理资源
docker system prune -a
```

---

## 📚 学习资源

### 项目文档
- 📘 [快速开始指南](QUICKSTART.md)
- 📗 [CI/CD 失败处理](docs/README.md)
- 📙 [详细处理文档](docs/CI-CD-FAILURE-HANDLING.md)

### 外部资源
- [FastAPI 文档](https://fastapi.tiangolo.com/)
- [Docker 文档](https://docs.docker.com/)
- [Jenkins 文档](https://www.jenkins.io/doc/)

---

## 🎯 学习目标

通过这个项目，你将学会：

- ✅ FastAPI 应用开发
- ✅ Docker 容器化技术
- ✅ Jenkins CI/CD 流水线配置
- ✅ 自动化测试和代码质量检查
- ✅ 优雅的部署策略
- ✅ 生产环境最佳实践

---

## 📄 许可证

MIT License

---

**Happy Coding! 🎉**
