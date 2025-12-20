"""
FastAPI 应用主文件
包含基础的 API 路由和健康检查接口
"""

import os
from datetime import datetime

from fastapi import FastAPI, HTTPException
from fastapi.middleware.cors import CORSMiddleware
from pydantic import BaseModel

# 创建 FastAPI 应用实例
app = FastAPI(
    title="FastAPI CI/CD Demo",
    description="一个用于学习 Jenkins CI/CD 流程的 FastAPI 示例项目",
    version="1.0.0",
)

# 配置 CORS
app.add_middleware(
    CORSMiddleware,
    allow_origins=["*"],
    allow_credentials=True,
    allow_methods=["*"],
    allow_headers=["*"],
)


class Item(BaseModel):
    """
    Item 模型
    代表一个商品实体
    """
    name: str
    description: str | None = None
    price: float
    tax: float | None = None


class MessageResponse(BaseModel):
    """
    MessageResponse 模型
    用于返回消息响应
    """
    message: str
    timestamp: str
    environment: str


# 模拟数据存储
items_db = {}


@app.get("/", response_model=MessageResponse)
async def root():
    """根路径 - 返回欢迎信息"""
    return MessageResponse(
        message="欢迎使用 FastAPI CI/CD Demo! 访问 /docs 查看 API 文档",
        timestamp=datetime.now().isoformat(),
        environment=os.getenv("APP_ENV", "development"),
    )


@app.get("/health")
async def health_check():
    """健康检查接口 - Jenkins 和 Docker 会用这个来检测服务是否正常"""
    return {
        "status": "healthy",
        "timestamp": datetime.now().isoformat(),
        "version": "1.0.0",
        "environment": os.getenv("APP_ENV", "development"),
    }


@app.get("/api/info")
async def get_info():
    """获取应用信息"""
    return {
        "app_name": "FastAPI CI/CD Demo",
        "version": "1.0.0",
        "python_version": os.sys.version,
        "environment": os.getenv("APP_ENV", "development"),
        "timestamp": datetime.now().isoformat(),
    }


@app.post("/api/items/{item_id}", response_model=Item)
async def create_item(item_id: int, item: Item):
    """创建商品"""
    if item_id in items_db:
        raise HTTPException(status_code=400, detail="商品已存在")
    items_db[item_id] = item
    return item


@app.get("/api/items/{item_id}", response_model=Item)
async def read_item(item_id: int):
    """获取商品详情"""
    if item_id not in items_db:
        raise HTTPException(status_code=404, detail="商品不存在")
    return items_db[item_id]


@app.get("/api/items")
async def list_items():
    """获取所有商品列表"""
    return {"total": len(items_db), "items": items_db}


@app.put("/api/items/{item_id}", response_model=Item)
async def update_item(item_id: int, item: Item):
    """更新商品信息"""
    if item_id not in items_db:
        raise HTTPException(status_code=404, detail="商品不存在")
    items_db[item_id] = item
    return item


@app.delete("/api/items/{item_id}")
async def delete_item(item_id: int):
    """删除商品"""
    if item_id not in items_db:
        raise HTTPException(status_code=404, detail="商品不存在")
    del items_db[item_id]
    return {"message": "商品已删除", "item_id": item_id}


if __name__ == "__main__":
    import uvicorn

    uvicorn.run(app, host="0.0.0.0", port=8000, log_level="info")  # nosec B104
