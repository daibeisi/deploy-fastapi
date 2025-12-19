# uv 包管理器使用指南

本项目使用 [uv](https://docs.astral.sh/uv/) 进行 Python 依赖管理。

## 快速开始

### 安装 uv

#### Linux/macOS
```bash
curl -LsSf https://astral.sh/uv/install.sh | sh
```

#### Windows (PowerShell)
```powershell
powershell -c "irm https://astral.sh/uv/install.ps1 | iex"
```

### 初始化项目

```bash
# 安装所有依赖（包括开发依赖）
uv sync --all-extras

# 或只安装生产依赖
uv sync
```

## 常用命令

### 运行应用
```bash
uv run uvicorn app.main:app --reload
```

### 开发工具
```bash
# 运行测试
uv run pytest tests/ -v

# 代码格式化
uv run black app/

# 代码检查
uv run flake8 app/

# 安全扫描
uv run bandit -r app/ -ll
```

### 依赖管理
```bash
# 添加生产依赖
uv add <package-name>

# 添加开发依赖
uv add --dev <package-name>

# 更新依赖
uv sync

# 查看已安装的包
uv pip list
```

## 优势

- ⚡ **极速安装**：比 pip 快 10-100 倍
- 🔒 **锁定版本**：uv.lock 确保可重现构建
- 🎯 **零配置**：自动管理虚拟环境（.venv/）
- 📦 **统一工具**：包管理、环境管理、脚本运行一体化

## 项目配置

所有配置在 `pyproject.toml` 中：
- 生产依赖：`[project.dependencies]`
- 开发依赖：`[project.optional-dependencies.dev]`
- 工具配置：`[tool.black]`, `[tool.pytest.ini_options]` 等

## CI/CD

Jenkins 流水线自动处理：
- 自动安装 uv（如果不存在）
- 运行 `uv sync --all-extras` 安装依赖
- 使用 `uv run` 执行所有检查和测试

## Docker

Dockerfile 使用 uv：
- 构建阶段：`uv sync --no-dev --frozen`
- 运行阶段：复制 `.venv` 虚拟环境

## 参考资料

- [uv 官方文档](https://docs.astral.sh/uv/)
- [uv GitHub](https://github.com/astral-sh/uv)
