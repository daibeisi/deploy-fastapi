# CI/CD 失败处理详细指南

## 📋 各阶段失败处理

### 1. Flake8 代码规范检查

**失败示例：**
```
❌ Flake8 检查失败！
app/main.py:25:1: F821 undefined name 'undefined_variable'
app/main.py:30:1: E999 SyntaxError: invalid syntax
```

**修复方法：**
```bash
# 本地检查
flake8 app/ --count --select=E9,F63,F7,F82 --show-source

# 修复后提交
git add .
git commit -m "fix: 修复代码规范问题"
git push
```

**忽略特定检查：**
```python
# 在代码中
from module import unused  # noqa: F401

# 或在 setup.cfg 中
[flake8]
exclude = .git,__pycache__,build,dist
```

---

### 2. Black 代码格式检查

**失败示例：**
```
⚠️ 代码格式不符合规范
would reformat app/main.py
1 file would be reformatted
```

**修复方法：**
```bash
# 自动格式化
black app/

# 检查格式
black --check app/

# 提交
git add .
git commit -m "style: 格式化代码"
git push
```

---

### 3. Bandit 安全扫描

**失败示例：**
```
⚠️ 发现安全问题
Issue: [B608:hardcoded_sql_expressions] Possible SQL injection
Location: app/main.py:45
```

**修复方法：**
```bash
# 查看详细报告
bandit -r app/ -ll -f txt

# 修复安全问题（使用参数化查询、移除硬编码密码等）
git add .
git commit -m "security: 修复安全漏洞"
git push
```

---

### 4. 单元测试失败

**失败示例：**
```
❌ 单元测试失败！
FAILED tests/test_main.py::test_create_item - assert 200 == 400
FAILED tests/test_main.py::test_health_check - AssertionError
2 failed, 8 passed in 1.23s
```

**修复方法：**
```bash
# 本地运行测试
pytest tests/ -v

# 查看详细错误
pytest tests/ -v --tb=long

# 运行特定测试
pytest tests/test_main.py::test_create_item -v

# 修复后提交
git add .
git commit -m "fix: 修复单元测试"
git push
```

---

### 5. Docker 镜像构建失败

**失败示例：**
```
❌ 镜像构建失败
ERROR: failed to solve: process "/bin/sh -c pip install -r requirements.txt" 
did not complete successfully: exit code: 1
```

**修复方法：**
```bash
# 本地测试构建
docker build -t test-build .

# 无缓存构建（查看详细错误）
docker build --no-cache -t test-build .

# 常见问题：
# 1. requirements.txt 中包不存在
# 2. 网络问题
# 3. Dockerfile 语法错误

# 修复后重新构建
git add .
git commit -m "fix: 修复 Docker 构建问题"
git push
```

---

### 6. 健康检查失败

**失败示例：**
```
❌ 健康检查失败
健康检查未通过，重试 (30/30)...
请查看日志: docker logs fastapi-cicd-app
```

**排查方法：**
```bash
# 查看容器日志
docker logs fastapi-cicd-app

# 查看容器状态
docker ps -a

# 进入容器检查
docker exec -it fastapi-cicd-app bash
curl localhost:8000/health

# 常见问题：
# 1. 端口被占用
# 2. 依赖缺失
# 3. 配置错误
# 4. 启动超时

# 手动测试健康检查
curl http://localhost:8000/health
```

---

## 🔧 故障排查指南

### 问题 1：端口被占用
```bash
# Windows
netstat -ano | findstr :8000
taskkill /PID <PID> /F

# Linux/Mac
lsof -i :8000
kill -9 <PID>
```

### 问题 2：测试在 CI 中失败，本地通过
```bash
# 检查环境差异
# 1. Python 版本
python --version

# 2. 依赖版本
pip list

# 3. 环境变量
env | grep APP

# 使用 Docker 模拟 CI 环境
docker run -it --rm -v $(pwd):/app python:3.11-slim bash
cd /app && pip install -r requirements.txt
pytest tests/
```

### 问题 3：Docker 容器无法启动
```bash
# 查看容器日志
docker logs fastapi-cicd-app

# 查看容器详细信息
docker inspect fastapi-cicd-app

# 进入容器调试
docker run -it --rm fastapi-cicd-app bash

# 检查健康状态
docker inspect --format='{{.State.Health.Status}}' fastapi-cicd-app
```

---

## 💡 最佳实践

### 1. 提交前本地检查
```bash
# 运行完整检查
.\scripts\pre-commit-check.ps1

# 或分步检查
flake8 app/
black app/ --check
bandit -r app/ -ll
pytest tests/
```

### 2. 设置 Git Hooks
```bash
# 创建 .git/hooks/pre-commit
#!/bin/bash
echo "运行代码检查..."
flake8 app/ --select=E9,F63,F7,F82 || exit 1
pytest tests/ -q || exit 1
echo "✅ 所有检查通过"
```

### 3. 使用 Jenkins 通知
在 Jenkinsfile 的 post 部分配置：
```groovy
post {
    failure {
        emailext (
            subject: "❌ Build Failed: ${env.JOB_NAME}",
            body: "查看详情: ${env.BUILD_URL}console",
            to: 'your-email@example.com'
        )
    }
}
```

---

## 🎯 测试失败场景（学习用）

### 制造 Flake8 失败：
```python
# 在 app/main.py 中添加
def bad_function():
    return undefined_variable  # F821 错误
```

### 制造单元测试失败：
```python
# 修改 app/main.py
@app.get("/health")
async def health_check():
    return {"status": "unhealthy"}  # 改为 unhealthy
```

### 制造 Docker 构建失败：
```txt
# 在 requirements.txt 中添加
non-existent-package==999.999.999
```

**⚠️ 注意：** 在测试分支测试，不要在 main 分支！

---

## 📊 Jenkins 查看失败详情

```
控制台日志: http://localhost:8080/job/<job-name>/lastBuild/console
测试报告:   http://localhost:8080/job/<job-name>/lastBuild/testReport/
构建历史:   http://localhost:8080/job/<job-name>/
```

---

## 🔗 相关文件

- [Jenkinsfile](../Jenkinsfile) - 流水线配置
- [deploy.sh](../deploy.sh) - 部署脚本
- [预检查脚本](../scripts/) - 本地检查工具

---

**记住：** 严重问题阻断部署，次要问题警告，确保代码质量！
