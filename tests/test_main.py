"""
API 端点测试
"""
from fastapi.testclient import TestClient
from app.main import app

client = TestClient(app)

def test_read_root():
    """测试根路径"""
    response = client.get("/")
    assert response.status_code == 200
    data = response.json()
    assert "message" in data
    assert "timestamp" in data
    assert "environment" in data

def test_health_check():
    """测试健康检查接口"""
    response = client.get("/health")
    assert response.status_code == 200
    data = response.json()
    assert data["status"] == "healthy"
    assert "timestamp" in data
    assert "version" in data

def test_get_info():
    """测试应用信息接口"""
    response = client.get("/api/info")
    assert response.status_code == 200
    data = response.json()
    assert data["app_name"] == "FastAPI CI/CD Demo"
    assert data["version"] == "1.0.0"

def test_create_item():
    """测试创建商品"""
    item_data = {
        "name": "测试商品",
        "description": "这是一个测试商品",
        "price": 99.99,
        "tax": 10.0
    }
    response = client.post("/api/items/1", json=item_data)
    assert response.status_code == 200
    data = response.json()
    assert data["name"] == item_data["name"]
    assert data["price"] == item_data["price"]

def test_read_item():
    """测试获取商品"""
    # 先创建商品
    item_data = {
        "name": "测试商品",
        "description": "这是一个测试商品",
        "price": 99.99
    }
    client.post("/api/items/2", json=item_data)
    
    # 获取商品
    response = client.get("/api/items/2")
    assert response.status_code == 200
    data = response.json()
    assert data["name"] == item_data["name"]

def test_read_nonexistent_item():
    """测试获取不存在的商品"""
    response = client.get("/api/items/999")
    assert response.status_code == 404

def test_list_items():
    """测试获取商品列表"""
    response = client.get("/api/items")
    assert response.status_code == 200
    data = response.json()
    assert "total" in data
    assert "items" in data

def test_update_item():
    """测试更新商品"""
    # 先创建商品
    item_data = {
        "name": "原商品名",
        "description": "原描述",
        "price": 50.0
    }
    client.post("/api/items/3", json=item_data)
    
    # 更新商品
    updated_data = {
        "name": "新商品名",
        "description": "新描述",
        "price": 60.0
    }
    response = client.put("/api/items/3", json=updated_data)
    assert response.status_code == 200
    data = response.json()
    assert data["name"] == updated_data["name"]
    assert data["price"] == updated_data["price"]

def test_delete_item():
    """测试删除商品"""
    # 先创建商品
    item_data = {
        "name": "待删除商品",
        "price": 30.0
    }
    client.post("/api/items/4", json=item_data)
    
    # 删除商品
    response = client.delete("/api/items/4")
    assert response.status_code == 200
    data = response.json()
    assert data["message"] == "商品已删除"
    assert data["item_id"] == 4
    
    # 验证商品已被删除
    response = client.get("/api/items/4")
    assert response.status_code == 404
