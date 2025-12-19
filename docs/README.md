# CI/CD 失败处理机制

## 🎯 失败处理策略

| 检查项 | 失败时处理 | 是否阻断 | 说明 |
|--------|-----------|---------|------|
| **Flake8** | ❌ 构建失败 | ✅ 是 | 语法错误、未定义变量等 |
| **Black** | ⚠️ 标记 Unstable | ❌ 否 | 代码格式问题 |
| **Bandit** | ⚠️ 标记 Unstable | ❌ 否 | 安全扫描警告 |
| **Pytest** | ❌ 构建失败 | ✅ 是 | 单元测试失败 |
| **Docker** | ❌ 构建失败 | ✅ 是 | 镜像构建失败 |
| **Health** | ❌ 部署失败 + 回滚 | ✅ 是 | 健康检查失败 |

---

## 🔄 典型失败场景

### 场景 1: 代码规范检查失败
```bash
# 错误示例
app/main.py:25:1: F821 undefined name 'undefined_variable'

# 修复方法
flake8 app/ --show-source  # 查看详细错误
# 修复代码后重新提交
```

### 场景 2: 单元测试失败
```bash
# 错误示例
FAILED tests/test_main.py::test_create_item

# 修复方法
pytest tests/ -v  # 查看详细错误
# 修复代码或测试后重新提交
```

### 场景 3: 健康检查失败
```bash
# 错误示例
curl: (7) Failed to connect to localhost port 8000

# 排查方法
docker logs fastapi-cicd-app  # 查看容器日志
# 检查端口占用、配置错误等
```

---

## 🛠️ 本地预检查

提交前运行（强烈推荐）：

```bash
# Windows
.\scripts\pre-commit-check.ps1

# Linux/Mac
./scripts/pre-commit-check.sh
```

---

## 📊 调整严格程度

在 [Jenkinsfile](../Jenkinsfile) 中修改：

```groovy
// Black 改为强制
if (blackResult != 0) {
    error('❌ 代码格式检查失败！')  // 从 unstable 改为 error
}

// Bandit 改为强制
if (banditResult != 0) {
    error('❌ 安全扫描失败！')  // 取消注释
}
```

---

## 📚 相关资源

- [详细处理文档](CI-CD-FAILURE-HANDLING.md) - 包含所有场景的修复方法
- [Jenkinsfile](../Jenkinsfile) - 完整流水线配置
- [部署脚本](../deploy.sh) - 部署和健康检查逻辑

---

**核心原则：** 严重问题阻断部署，次要问题警告但不阻断，确保只有高质量代码才能上线。
