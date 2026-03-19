# 2026-03-19 Public README Gemini Art Direction

## Goal

基于仓库作者提供的 `Gemini_Generated_Image_75f8n575f8n575f8.svg` 重构 README 首屏视觉，把当前偏产品海报式的展示升级为更有编辑感的双栏版式。

## Deliverables

- 基于作者提供的 SVG 主要样式生成一个 README 右栏艺术窗格
- 基于作者提供的 SVG 主要样式生成一个新的顶部识别 mark
- 重构 `README.md` 首屏排布
- 同步重构 `README.en.md` 首屏排布
- 新增本轮 requirement、design、plan 文档
- 更新 `docs/requirements/README.md` 与 `docs/plans/README.md`

## Constraints

- 必须保留 GitHub README 原生渲染兼容性
- 原图可以被裁切、重组、再版式化，但不能丢失主要样式气质
- 不要求整张图直接原样铺满 README
- 首屏要实现“好看”和“信息可读”同时成立
- 新版 logo 和海报要与原图属于同一视觉家族
- README 仍然要服务于公开入口，而不是变成纯艺术页

## Acceptance Criteria

- 用户在首屏看到的是“左信息、右艺术”的平衡式排布
- 新的顶部识别 mark 明显来自作者原图的样式语言
- 右侧艺术窗格明显比整图直贴更有版式感
- 首屏信息密度保留，但比上一版更克制、更编辑化
- 中英文版本都完成同一套版式升级

## Non-Goals

- 不修改 runtime、router、setup、install 等功能逻辑
- 不新增外部前端依赖
- 不把 README 变成纯图片墙
- 不要求精确还原原图全部内容

## Frozen User Intent

用户明确要求：

- 使用自己新绘制的 `Gemini_Generated_Image_75f8n575f8n575f8.svg`
- 以原图“主要样式”为基准更新最终展示的 logo 和海报
- 注意原图空白很多，可以自行设计版式，不必整张照搬
- 重点不是机械替换图片，而是“如何让它在 README 中有设计感的排布”
- 方向选择为 `B`：平衡型，视觉和信息密度同时成立

## Evidence Strategy

- 通过新增资产文件验证 panel 与 mark 都已入库
- 通过首屏片段检查验证双栏 hero、识别 mark、数字条和正文顺序
- 通过 `git diff --stat` 验证改动集中在 README、资产和治理索引
