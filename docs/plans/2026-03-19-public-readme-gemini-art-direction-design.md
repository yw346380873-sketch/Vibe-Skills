# Public README Gemini Art Direction Design

## Intent

这一轮不是“换一张新图”，而是把作者自己的 SVG 变成 README 首屏的主视觉语言。

上一版首屏更像产品海报：信息完整、节奏清晰，但主视觉是我们自己生成的抽象章鱼系统图。现在的目标是让仓库作者提供的图成为视觉权威，同时保留首页作为公开入口的功能性。

## Chosen Direction

采用 `Balanced Editorial Hero`：

- 左侧承担标题、判断句、关键数字与极短说明
- 右侧承担艺术窗格
- 顶部识别 mark 来自同一张原图的局部裁切

这让 README 更像一张有设计感的杂志封面页，而不是传统开源仓库首页。

## Source Style Reading

作者原图的核心特征：

- 大量留白
- 深靛蓝、灰紫、冷白、冰蓝一组更精致的配色
- 色块叠加多、细节密度高、没有明显描边
- 更像插画型 SVG，而不是极简图标型 SVG

因此不应该整张铺满，而应该做“局部截取 + 版式重组”。

## Asset Strategy

### 1. Editorial Panel

基于原图的主要配色、明暗关系和插画节奏，生成一个更适合 README 的纵向 panel：

- `docs/assets/vibeskills-gemini-editorial-panel.svg`

这个 panel 不求展示原图全部内容，而是提炼它的主样式并承担右栏“艺术窗格”的角色。

### 2. Gemini Mark

基于同一套风格语言生成更紧凑的方形识别 mark：

- `docs/assets/vibeskills-gemini-mark.svg`

这样 logo 与主图属于同一视觉家族，不再割裂。

## README Layout

首屏排布改成：

1. 语言切换
2. 双栏 hero
3. 左栏标题与判断句
4. 左栏数字条
5. 右栏艺术窗格
6. 下方系统说明与路径入口

## Information Density Strategy

上一版的三张统计卡信息是对的，但视觉上更偏“产品功能面板”。这一轮改成更轻的数字条：

- 340 skills
- 19 upstreams
- 129 policies

这样既保留事实，又不会抢走艺术窗格的视觉重心。

## Success Condition

如果这次设计成立，README 首屏会同时具有三种阅读价值：

1. 一眼能记住视觉气质
2. 两眼能明白这不是普通 skills 仓库
3. 三眼还能找到继续阅读的路径
