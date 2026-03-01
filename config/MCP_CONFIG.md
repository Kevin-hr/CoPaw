# MCP 配置说明 - Coding Plan Lite

## ✅ 已配置的 MCP

### 1. 联网搜索 MCP (Tavily)
**状态**: ✅ 已启用  
**配置位置**: `config.json` → `mcp.clients.tavily_search`

#### 配置详情：
```json
{
  "name": "tavily_mcp",
  "enabled": true,
  "command": "npx",
  "args": ["-y", "tavily-mcp@latest"],
  "env": {
    "TAVILY_API_KEY": "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"
  }
}
```

#### 获取 API Key：
1. 访问 https://app.tavily.com
2. 注册/登录账号
3. 进入 Dashboard → API Keys
4. 创建新密钥
5. 替换 `config.json` 中的 `TAVILY_API_KEY`

#### 免费额度：
- 每月 1000 次搜索
- 适合个人使用

---

### 2. 图片理解 Skill (阿里云百炼)
**状态**: ✅ 已启用  
**配置位置**: `config.json` → `mcp.clients.image_understanding`

#### 配置详情：
```json
{
  "name": "image_understanding_mcp",
  "enabled": true,
  "command": "npx",
  "args": ["-y", "@aliyun/image-understanding-mcp@latest"],
  "env": {
    "DASHSCOPE_API_KEY": "sk-7d2f8a9b3c4e5f6g7h8i9j0k1l2m3n4o"
  }
}
```

#### 获取 API Key：
1. 访问 https://bailian.console.aliyun.com
2. 登录阿里云账号
3. 进入 **模型服务** → **API-KEY 管理**
4. 创建新密钥（或查看已有密钥）
5. 替换 `config.json` 中的 `DASHSCOPE_API_KEY`

#### Coding Plan Lite 额度：
- 新人免费额度：¥200
- 有效期：180 天
- 适用模型：qwen-vl-plus, qwen-vl-max

---

## 🔧 验证配置

### 验证命令：
```bash
# 检查 MCP 配置
copaw mcp list

# 测试 Tavily 搜索
copaw mcp test tavily_search

# 测试图片理解
copaw mcp test image_understanding
```

### 验证步骤：
1. 打开浏览器访问阿里云百炼控制台
2. 确认账号已登录
3. 检查 API Key 是否有效
4. 确认套餐余额充足

---

## 📊 使用示例

### 联网搜索示例：
```
用户：帮我搜索最新的 AI 新闻
→ 自动调用 Tavily MCP
→ 返回搜索结果摘要
```

### 图片理解示例：
```
用户：[上传图片] 这张图片里有什么？
→ 自动调用图片理解 MCP
→ 返回图片分析结果
```

---

## ⚠️ 注意事项

### 1. API Key 安全
- ❌ 不要分享 API Key
- ❌ 不要提交到代码仓库
- ✅ 定期轮换密钥
- ✅ 使用环境变量存储

### 2. 额度管理
- 定期检查使用量
- 设置使用提醒
- 避免超出配额

### 3. 故障排查
- 检查网络连接
- 验证 API Key 有效性
- 查看日志文件

---

## 🔗 相关文档

- Tavily 文档：https://docs.tavily.com
- 阿里云百炼：https://help.aliyun.com/zh/dashscope
- Coding Plan：https://bailian.console.aliyun.com/cn-beijing/?tab=doc#/doc/?type=model&url=3023217
- 图片理解 Skill：https://bailian.console.aliyun.com/cn-beijing/?tab=doc#/doc/?type=model&url=3023166

---

**配置日期**: 2026-03-02  
**套餐**: Coding Plan Lite  
**状态**: ✅ 配置完成
