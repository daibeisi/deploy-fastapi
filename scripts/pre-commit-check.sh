#!/bin/bash

# ============================================
# 提交前代码质量检查脚本
# 在本地运行所有 CI/CD 中的检查
# ============================================

set -e  # 遇到错误立即退出

# 颜色输出
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

# 计数器
TOTAL_CHECKS=0
PASSED_CHECKS=0
FAILED_CHECKS=0

echo ""
echo "============================================"
echo "  代码质量检查 - Pre-commit Check"
echo "============================================"
echo ""

# 检查 1: Flake8 代码规范
echo -e "${BLUE}[1/4]${NC} 运行 Flake8 代码规范检查..."
TOTAL_CHECKS=$((TOTAL_CHECKS + 1))
if flake8 app/ --count --select=E9,F63,F7,F82 --show-source --statistics; then
    echo -e "${GREEN}✓ Flake8 检查通过${NC}"
    PASSED_CHECKS=$((PASSED_CHECKS + 1))
else
    echo -e "${RED}✗ Flake8 检查失败${NC}"
    FAILED_CHECKS=$((FAILED_CHECKS + 1))
    echo -e "${YELLOW}修复建议: 检查语法错误、未定义变量等问题${NC}"
fi
echo ""

# 检查 2: Black 代码格式
echo -e "${BLUE}[2/4]${NC} 运行 Black 代码格式检查..."
TOTAL_CHECKS=$((TOTAL_CHECKS + 1))
if black --check app/; then
    echo -e "${GREEN}✓ Black 格式检查通过${NC}"
    PASSED_CHECKS=$((PASSED_CHECKS + 1))
else
    echo -e "${YELLOW}⚠ 代码格式不符合规范${NC}"
    echo -e "${YELLOW}自动修复: black app/${NC}"
    FAILED_CHECKS=$((FAILED_CHECKS + 1))
fi
echo ""

# 检查 3: Bandit 安全扫描
echo -e "${BLUE}[3/4]${NC} 运行 Bandit 安全扫描..."
TOTAL_CHECKS=$((TOTAL_CHECKS + 1))
if bandit -r app/ -ll -q; then
    echo -e "${GREEN}✓ 安全扫描通过${NC}"
    PASSED_CHECKS=$((PASSED_CHECKS + 1))
else
    echo -e "${YELLOW}⚠ 发现潜在安全问题${NC}"
    echo -e "${YELLOW}查看详情: bandit -r app/ -ll${NC}"
    FAILED_CHECKS=$((FAILED_CHECKS + 1))
fi
echo ""

# 检查 4: 单元测试
echo -e "${BLUE}[4/4]${NC} 运行单元测试..."
TOTAL_CHECKS=$((TOTAL_CHECKS + 1))
if pytest tests/ -q; then
    echo -e "${GREEN}✓ 单元测试通过${NC}"
    PASSED_CHECKS=$((PASSED_CHECKS + 1))
else
    echo -e "${RED}✗ 单元测试失败${NC}"
    FAILED_CHECKS=$((FAILED_CHECKS + 1))
    echo -e "${YELLOW}查看详情: pytest tests/ -v${NC}"
fi
echo ""

# 总结
echo "============================================"
echo "  检查结果汇总"
echo "============================================"
echo -e "总计: ${TOTAL_CHECKS} 项"
echo -e "${GREEN}通过: ${PASSED_CHECKS} 项${NC}"
echo -e "${RED}失败: ${FAILED_CHECKS} 项${NC}"
echo "============================================"
echo ""

# 如果有失败，退出码非零
if [ $FAILED_CHECKS -gt 0 ]; then
    echo -e "${RED}❌ 代码检查未通过，请修复后再提交${NC}"
    echo ""
    exit 1
else
    echo -e "${GREEN}✅ 所有检查通过，可以安全提交！${NC}"
    echo ""
    exit 0
fi
