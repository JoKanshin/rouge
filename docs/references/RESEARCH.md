# 企划参考与技能来源记录

检索与访问日期：2026 年 10 月 26 日。

## 用户给出的参考

- [原帖](https://linux.do/t/topic/2981705)：通过浏览器读到首帖及展开的初始提示词。主要参考“明确定位、统一风格、攻击反馈、局内构筑、敌人与 Boss”的表达组织。作者使用的模型、制作耗时和作品水平是其自述，本次未独立验证。
- [用户提供的旧试玩链接](https://pmcat.top/games/achroma/index.html)：当前访问显示 PM-API 首页。
- [首帖当前试玩链接](https://game.unsnow.online/ach/)：访问标题界面、难度选择和局内起始提示。没有完成整局，也没有对其地图生成与战斗质量作实测结论。
- 用户截图：参考章节组织与具体描述方式，不把其中第三人称、2.5D 射击或角色故事当成本项目要求。

## 作品一手资料

- [空洞骑士官网](https://www.hollowknight.com/)：官方定位为 2D 动作冒险，并强调相连世界、探索和能力成长。
- [死亡细胞官网](https://dead-cells.com/)：官方介绍强调动作平台、模式化敌人、不同武器玩法、非线性路线与探索。
- [赛菲莉娅官方商店](https://store.steampowered.com/app/2436940/Sephiria/?l=schinese) 与 [开发者公告](https://steamcommunity.com/app/2436940/announcements/)：按用户补充检索，确认了物品栏摆放与强化、武器效果联动、按操作条件进化的部分装备，以及试用已解锁装备的训练功能。未安装或完整试玩该游戏；灯匣、动作计数和本项目遗物效果是转化方案。

本企划中的具体帧数、金币、房间数、敌人、流派和制作阶段均为项目设计建议，没有将它们冒充为上述作品的原始机制数据。

## 已获取技能

上游：[gamedev-skills/awesome-gamedev-agent-skills](https://github.com/gamedev-skills/awesome-gamedev-agent-skills)。使用 skill-installer 的下载模式，选取六个目录，保存到项目 `.agents/skills/`，包含各自引用的 references。未执行上游示例脚本。

| 本地名称 | 上游目录 | 本次采用的原则 |
| --- | --- | --- |
| platformer | skills/genres/platformer | 先验证移动，容错与缓冲，跳跃能力约束平台 |
| godot-2d-movement | skills/godot/godot-2d-movement | 固定物理步进与 Godot 4 原生角色碰撞 |
| game-feel | skills/disciplines/game-feel | 按事件分级叠加短促反馈，停顿不吞输入 |
| game-ai | skills/disciplines/game-ai | 决策、运动和寻路分别管理，显式状态 |
| procedural-gen | skills/disciplines/procedural-gen | 确定性种子、加权生成、有限重试、可达性验证 |
| level-design | skills/disciplines/level-design | 先测移动尺度，灰盒教学，紧张与休息交替 |

这些技能是方法参考；本项目的房间组合、热量技能、敌人规则、资源结算和遗物触发方案由本企划定义。尤其是程序生成中的俯视网格算法，不能直接保证重力环境下的横版通行。

上游采用 Apache-2.0。随附 [LICENSE](GAMEDEV_SKILLS_LICENSE) 与 [NOTICE](GAMEDEV_SKILLS_NOTICE)。获取后查询到的 main 版本见 [版本记录](GAMEDEV_SKILLS_REVISION.txt)；该值记录查询时的仓库头，技能下载采用 main 快照，未声称经过固定 SHA 安装。

技能已放在项目发现目录，后续轮次可使用。若当前会话的可用技能列表尚未刷新，开发提示词已明确要求按需读取本地文件。

## 交付边界

最初规划轮次新增企划、开发提示词、参考记录与技能文件。用户随后提交开发提示词，授权执行 A 阶段；A 阶段的实现与检查以 STAGE_A_REPORT.md 为准。企划中的 B–D 与 C2 仍是待实施项。
