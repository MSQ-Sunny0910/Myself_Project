# 马思琪 · 个人作品集

基于简历生成的个人作品集页面，数据与视图分离：

- `portfolio.html` — 页面结构与渲染逻辑
- `portfolio_data.txt` — JSON 格式数据源（个人信息、工作经历、项目经历、专业技能）
- `database_schema.sql` — 后端数据库三表设计参考

## 本地预览

因为页面通过 `fetch` 读取 `portfolio_data.txt`，请使用本地 HTTP 服务打开，避免浏览器 file 协议 CORS 限制：

```bash
# 进入本目录
python -m http.server 8080
```

然后访问 `http://127.0.0.1:8080/portfolio.html`。

## 更新内容

修改 `portfolio_data.txt` 中的 JSON 数据即可，无需改动 HTML。

- 项目图片：在对应项目的 `images` 数组中填入图片 URL
- 项目详情链接：在对应项目的 `detail` 字段填入真实链接（填 `#` 或空则不显示链接）
- 专业技能：在 `skills` 数组中维护

## 部署到 GitHub Pages（可选）

1. 将本目录推送到 GitHub 仓库
2. 进入仓库 Settings → Pages → Branch，选择 `master` / `main` 分支，文件夹选 `/ (root)`
3. 访问 `https://<你的用户名>.github.io/<仓库名>/portfolio.html`
