extends "res://scripts/arena_hud.gd"
const NAMES = ["旧矿道","回声回廊","断梁矿层","灰烬深井","熄炉底层","黑石裂隙","余热尽头"]

func _input(_event): pass

func _draw():
	if not is_instance_valid(arena.player) or arena.world.is_empty(): return
	var p = arena.player
	panel(Rect2(0,0,640,66),Color(0.035,0.055,0.075,0.95))
	text("灰烬之下",14,23,17,GOLD)
	text("%s · 连续矿区"%NAMES[arena.current_layer()],14,43,10,MUTED)
	panel(Rect2(153,13,126,10),Color("392f36"))
	panel(Rect2(153,13,126.0*p.hp/100,10),Color("b77c73"))
	text("生命 %d"%p.hp,157,21,9)
	panel(Rect2(153,30,126,6),Color("27353b"))
	panel(Rect2(153,30,126.0*p.heat/100,6),Color("86b8af"))
	text("药 %d   热 %d/60"%[p.potions,p.heat],153,51,10,MUTED)
	text("金币 %d  /  存款 %d"%[arena.coins,arena.bank],296,22,11,GOLD)
	text("探索 %d%%   击破 %d"%[int(100.0*arena.explored.size()/arena.world.route_nodes.size()),arena.defeated.size()],296,42,10,MUTED)
	draw_map(Rect2(454,8,174,48),false)
	panel(Rect2(0,374,640,26),Color(0.035,0.055,0.075,0.97))
	text("AD 移动  空格 跳跃  J 斩击  K 冲刺  L 重击  Q 灯焰",12,390,9)
	text("Tab 地图  F7 参数  F1 帮助",440,390,9,GOLD)
	if not arena.interaction.is_empty() and not arena.dead:
		panel(Rect2(92,338,456,24),Color(0.05,0.08,0.11,0.94))
		text(arena.interaction,108,354,11,GOLD)
	if arena.message_clock > 0:
		panel(Rect2(12,72,616,24),Color(0.05,0.08,0.11,0.94))
		text(arena.message,22,88,10,GOLD)
	if arena.debug_shapes:
		text("种子 %d · %d×%d · 活跃敌人 %d · 碰撞体 %d"%[arena.world.config.seed,arena.world_bounds.size.x,arena.world_bounds.size.y,arena.active_enemies,arena.geometry.get_child_count()],12,112,10,MUTED)
	if arena.dead:
		overlay("灯还没有熄灭","E 回到最近篝火；已回收物资和击败的敌人保留。")
		text("随身金币 %d   仓库存款 %d"%[arena.coins,arena.bank],80,175,16,GOLD)
		text("本次死亡已扣除 40% 随身金币。",80,215,12)
		text("E 继续探索    F8 载入最近保存",80,295,13,GOLD)
	elif arena.map_open:
		panel(Rect2(0,0,640,400),Color(0.025,0.045,0.065,0.98))
		text("巡灯人的矿区图",22,33,21,GOLD)
		text("种子 %d · %d × %d 像素 · 已探索区域"%[arena.world.config.seed,arena.world_bounds.size.x,arena.world_bounds.size.y],22,55,11,MUTED)
		draw_map(Rect2(22,80,596,240),true)
		text("青色：所在位置   金色：篝火 / 升降机   小方块：物资箱",22,351,11)
		text("暗线：尚未探索的岔路入口    Tab / Esc 返回",22,377,11,GOLD)
	elif arena.help_visible:
		overlay("深入一片连续矿区","沿横向矿道探索，用纵井在不同深度间穿行。")
		var lines = ["AD / 方向键移动；空格跳跃，S 下蹲，↓ 空格穿下木平台。","J 三段斩击；↑ J 上挑；空中 ↓ J 下劈；L 重击，K 冲刺。","Q 消耗 60 热量释放灯焰；R 喝药，受击打断。","E 开箱 / 篝火补给；篝火旁 T 存金币；最深层右端为出口。","Tab 查看探索地图；F7 调整种子、大小、纵井、宝箱与敌人。","F5 保存；F8 继续；F9 战斗试验场；F10 从试验场返回。","F2 判定框；F3 震动；F4 闪光；F6 美术；M 静音。"]
		for i in range(lines.size()): text(lines[i],73,149+i*22,10)
	elif get_tree().paused and not arena.settings_open:
		overlay("暂歇片刻","Esc 继续 · F7 打开生成参数 · F1 帮助")

func draw_map(rect: Rect2,large: bool):
	var world = arena.world
	var scale_xy = rect.size/world.bounds.size
	var count = world.config.width_segments
	panel(rect,Color("0b131b"))
	for edge in world.route_edges:
		if edge[0] > edge[1]: continue
		var seen_a = arena.explored.has(edge[0])
		var seen_b = arena.explored.has(edge[1])
		if not seen_a and not seen_b: continue
		var a = rect.position+world.route_nodes[edge[0]]*scale_xy
		var b = rect.position+world.route_nodes[edge[1]]*scale_xy
		draw_line(a,b,Color("759496") if seen_a and seen_b else Color("33434b"),3 if large else 1)
	for object in world.objects:
		var layer = clampi(int((object.pos.y-32)/320),0,world.config.depth_layers-1)
		var segment = clampi(int((object.pos.x-32)/128),0,count-1)
		if not arena.explored.has(layer*count+segment): continue
		var pos = rect.position+object.pos*scale_xy
		var color = GOLD if object.kind in ["camp","entry","exit"] else MUTED
		if object.kind == "chest" and object.used: continue
		draw_rect(Rect2(pos-Vector2(2,2),Vector2(4,4)),color)
	var player_pos = rect.position+arena.player.position*scale_xy
	draw_circle(player_pos,4 if large else 2,Color("8bd2c5"))
