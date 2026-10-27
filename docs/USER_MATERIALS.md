# 用户提交的材料与参考地址

更新：2026 年 10 月 27 日。本清单属于 Claude 交接文档的一部分。保留用户原始地址；访问失败不等于没有参考价值，也不代表已经观看或试玩完成。

## 用户提供的外部链接

| 材料 | 用户提交的原地址 | 用途与当前读取情况 |
| --- | --- | --- |
| Linux.do 原帖 | https://linux.do/t/topic/2981705 | 用户说现有原型粗糙、地图不随机、战斗乏味，并让参考讨论。此前通过浏览器读取过帖子内容；作者的模型说法只作为作者自述，不当作已验证事实 |
| 原帖旧试玩地址 | https://pmcat.top/games/achroma/index.html | 用户最初给的试玩地址；此前访问显示 PM-API 首页，未获得原预期游戏。原地址保留，后续可重查 |
| 原帖当时的新试玩地址 | https://game.unsnow.online/ach/ | 助手从帖子发现的补充地址，查看过标题、难度与开场界面；没有完成整局试玩。不是用户最初那条地址，不要混淆 |
| silverlybee 教学视频 | https://www.youtube.com/watch?v=gHU5RQWbmWE&t=637s | 用户本次给出，时间戳为 637 秒；当前网页抓取失败，未声称观看视频或取得字幕 |
| silverlybee 仓库 | https://github.com/silverlybee/dungeon-generator | 用户本次给出。已读取 README、DungeonGenerator.cs、RoomBehaviour.cs；参考 DFS 连通与按位置选择内容的思路，适配横版后独立实现 |

用户附视频的说明原文：

> 要做一款令人沉浸且具有挑战的Roguelite/Roguelike游戏当然是不容易的事情，本期视频我们快速实现肉鸽游戏的一种制作方式，为各位喜欢游戏开发的小伙伴提供些许思路。
> 地牢生成器参考自油管Up silverlybee：https://www.youtube.com/watch?v=gHU5RQWbmWE&t=637s
> 转载其Github链接：https://github.com/silverlybee/dungeon-generator

仓库源码直达：[DungeonGenerator.cs](https://github.com/silverlybee/dungeon-generator/blob/main/DungeonGenerator.cs)、[RoomBehaviour.cs](https://github.com/silverlybee/dungeon-generator/blob/main/RoomBehaviour.cs)、[WallCollision.cs](https://github.com/silverlybee/dungeon-generator/blob/main/WallCollision.cs)。最后一个文件未成功抓取，不声称读过；包内没有复制该仓库代码。

## 用户点名的游戏

| 参考 | 可访问地址 | 用户希望参考的方向 |
| --- | --- | --- |
| 《空洞骑士》Hollow Knight | https://www.hollowknight.com/ | 起初参考侧视空间、读招和空中动作；最新要求进一步参考大地图的探索感，改成按数值生成的连续世界 |
| 《死亡细胞》Dead Cells | https://dead-cells.com/ | 动作衔接、攻击节奏、局内构筑与路线取舍 |
| 《赛菲莉娅》Sephiria | https://store.steampowered.com/app/2436940/Sephiria/?l=schinese | 用户原话称“赛菲利亚”，后核对商店名为“赛菲莉娅”。参考装备与招式联动、组合信息、构筑进化；保持本项目的侧视平台类型，不直接移植俯视移动 |

补充官方更新地址：https://steamcommunity.com/app/2436940/announcements/ 。这是助手研究时补充的来源。当前只是参考其已公开设计，没有安装或试玩这款游戏，也未把灯匣系统实现进当前原型。

## 用户提交的附件、文字与需求

### 1 初始游戏构想

用户最初要求像素风 2D 横版动作肉鸽，能左右移动、跳跃、下蹲、劈砍，有敌怪、宝箱、地表城镇补给与地牢金币收益。先不考虑正式美术。内容已进入 [总企划](GAME_DESIGN.md)；原始记录在本次聊天。

### 2 企划/提示词格式截图

原附件名：`codex-clipboard-7d570c8a-eac8-4665-85be-24669ad56cab.png`。

提交时原始路径：`C:/Users/38387/AppData/Local/Temp/codex-clipboard-7d570c8a-eac8-4665-85be-24669ad56cab.png`。

随包副本：[提示词格式截图](references/user_materials/prompt_template_reference.png)。图中是“爪爪特警 PAW S.W.A.T.”第三人称射击企划，用户要求参考其卖点、世界观、敌人、操作手感、界面等组织方式；它只是**文档模板**，不是让本项目改成动物射击游戏。

### 3 用户提交的《灰烬之下 2D 动作肉鸽开发提示词》

用户在聊天中粘贴完整指令，核心为 A 战斗试验场 → B 地图 → C 构筑与资源 → D 完整敌人/Boss；并明确先执行 A。项目内 [开发提示词](DEVELOPMENT_PROMPT.md) 保留该方向并随当前要求更新；战斗具体交付见 [A 阶段记录](STAGE_A_REPORT.md)。

该旧指令中的“12–15 个房间节点 / 独立场景门切换”已被最新连续大地图要求取代，不能作为当前地图实现目标。Boss、12 遗物、城镇整合仍是规划，尚未完成。

### 4 用户提交的《灰烬之下 AI 像素美术素材制作方案》

原附件路径：`C:/Users/38387/.codex/attachments/19dce3f1-eb53-499a-b5df-96f81241ed9a/已粘贴的文本.txt`。

随包原文副本：[用户粘贴的美术方案 v1.0](references/user_materials/pasted_pixel_art_plan_v1.txt)。该文本与当时项目方案 v1.0 一致。用户随后明确选择“生成 P0 素材并接入游戏”，已完成。

更新后的 [美术方案](PIXEL_ART_PLAN.md)、[P0 交付记录](art_reviews/P0_REPORT.md)、[原图与提示词目录](../art_source/prompts/p0_generation.json)、[资产清单](../assets/art/p0_manifest.json) 均在包内。当前图像生成工具方式属于历史流程，后续新美术方式遵循下面最新要求。

### 5 本轮连续地图要求与 Claude 交接要求

用户原话关键内容：

> 我希望有像空洞骑士那样的地图，一个地图很大，不是现在你的这种房间；地图是根据预设数值随机生成的。你先做一版，然后把这些东西打包，我准备让claude接手。

用户又明确：

> 记得再做一份文档给claude，说明现在的情况，然后加上一句美术相关的 用Claude 通过 Python 脚本绘制 SVG 图像，然后导出 png 格式。

> 我给你提交的材料你都要写进交接文档里，至少给个地址。

对应交付：[Claude 交接文档](CLAUDE_HANDOFF.md)、[连续地图记录](world_reviews/WORLD_REPORT.md)、根目录 `CLAUDE.md` 和完整项目 ZIP。当前美术按用户“目前美术先这样”的要求保持。

## 技能来源与本地资料

用户曾要求去 GitHub 等地获取适合的游戏开发技能。已获取仓库：https://github.com/gamedev-skills/awesome-gamedev-agent-skills 。包内 `.agents/skills/` 包含 platformer、godot-2d-movement、game-feel、game-ai、procedural-gen、level-design。不是从本轮 silverlybee 仓库获取的技能，不要混为一处。

许可证与获取记录：[Apache 2.0](references/GAMEDEV_SKILLS_LICENSE)、[NOTICE](references/GAMEDEV_SKILLS_NOTICE)、[版本记录](references/GAMEDEV_SKILLS_REVISION.txt)。其他更早研究见 [RESEARCH.md](references/RESEARCH.md)。
