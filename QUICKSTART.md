# 🚀 快速启动指南

## 第一步：启动应用

### 方式 A: Docker Compose（推荐）

```bash
# 启动应用
docker-compose up -d --build

# 查看日志
docker-compose logs -f app

# 访问应用
# http://localhost:8000
```

### 方式 B: 本地开发

```bash
# 创建虚拟环境
python -m venv venv

# 激活虚拟环境
venv\Scripts\activate  # Windows
# source venv/bin/activate  # Linux/Mac

# 安装依赖
pip install -r requirements.txt

# 运行应用
cd app
python main.py
```

## 第二步：验证部署

访问以下地址：

- ✅ 主页: http://localhost:8000
- ✅ API 文档: http://localhost:8000/docs
- ✅ 健康检查: http://localhost:8000/health

---

## 第三步：配置 Jenkins

### 1. 启动 Jenkins

```bash
docker run -d --name jenkins \
  -p 8080:8080 -p 50000:50000 \
  -v jenkins_home:/var/jenkins_home \
  -v /var/run/docker.sock:/var/run/docker.sock \
  jenkins/jenkins:lts

# 获取初始密码
docker exec jenkins cat /var/jenkins_home/secrets/initialAdminPassword
```

### 2. 初始化

1. 访问 http://localhost:8080
2. 输入初始密码
3. 安装推荐插件
4. 创建管理员账户

### 3. 安装必要插件

- Docker Pipeline
- Git Plugin
- Pipeline

### 4. 创建 Pipeline 项目

1. 新建任务 → 流水线
2. 配置 Git 仓库地址
3. 指定 Jenkinsfile 路径

---

## 第四步：测试 CI/CD

### 提交前本地检查（推荐）

```bash
# Windows
.\scripts\pre-commit-check.ps1

# Linux/Mac
./scripts/pre-commit-check.sh
```

### 提交代码

```bash
# 修改代码
# 例如修改 app/main.py 中的版本号

# 提交代码
git add .
git commit -m "test: 测试 CI/CD 流程"
git push origin main

# Jenkins 会自动触发构建
```

### 如果构建失败？

查看 Jenkins 控制台日志，根据错误信息修复：

```bash
# 代码规范问题
flake8 app/

# 格式问题
black app/

# 测试失败
pytest tests/ -v

# 或运行完整检查
.\scripts\pre-commit-check.ps1

# 修复后重新提交
git add .
git commit -m "fix: 修复构建问题"
git push
```

📖 [详细的失败处理文档](docs/CI-CD-FAILURE-HANDLING.md)

---

## 常用命令

```bash
# 查看容器状态
docker ps

# 查看应用日志
docker logs -f fastapi-cicd-app

# 重启应用
docker-compose restart app

# 停止服务
docker-compose down

# 手动执行部署
bash deploy.sh

# 进入容器
docker exec -it fastapi-cicd-app bash

# 运行测试
pytest tests/

# 清理 Docker 资源
docker system prune -a
```

---

## 故障排查

### 端口被占用

```bash
# Windows
netstat -ano | findstr :8000

# Linux/Mac
lsof -i :8000
```

### 容器无法启动

```bash
# 查看日志
docker logs fastapi-cicd-app

# 检查状态
docker ps -a

# 查看详情
docker inspect fastapi-cicd-app
```

### 健康检查失败

```bash
# 手动测试
curl http://localhost:8000/health

# 进入容器检查
docker exec -it fastapi-cicd-app bash
curl localhost:8000/health
```

---

## 下一步

- ✅ 熟悉 [Jenkinsfile](Jenkinsfile) 流水线配置
- ✅ 了解 [deploy.sh](deploy.sh) 部署脚本
- ✅ 阅读 [失败处理文档](docs/CI-CD-FAILURE-HANDLING.md)
- ✅ 测试各种失败场景
- ✅ 自定义你的 CI/CD 流程

---

**祝你学习愉快！🎉**
