extends Node2D
var arena: Node
var font: Font
const GOLD = Color("dfbf85")
const PALE = Color("d5dacf")
const MUTED = Color("7c9396")

func _ready():
	font = SystemFont.new()
	font.font_names = PackedStringArray(["Microsoft YaHei", "sans-serif"])

func _process(_dt): queue_redraw()

func text(value: String, x: float, y: float, size: int = 11, color: Color = PALE):
	draw_string(font, Vector2(x, y), value, HORIZONTAL_ALIGNMENT_LEFT, -1, size, color)

func panel(rect: Rect2, color: Color): draw_rect(rect, color)

func _input(event):
	if event is InputEventMouseButton and event.pressed and event.button_index == MOUSE_BUTTON_LEFT:
		var p = get_viewport().get_mouse_position()
		if p.y >= 59 and p.y < 83:
			var index = int((p.x - 18) / 122)
			if p.x >= 18 and index >= 0 and index < 5:
				arena.call_deferred("load_lesson", index)

func _draw():
	if not is_instance_valid(arena.player): return
	var p = arena.player
	panel(Rect2(0, 0, 640, 90), Color("0d151d"))
	panel(Rect2(0, 89, 640, 1), Color("374549"))
	text("灰烬之下", 18, 25, 18, GOLD)
	text("A  /  COMBAT LAB", 19, 43, 9, MUTED)
	text("生命", 169, 20, 10)
	panel(Rect2(198, 11, 120, 11), Color("392f36"))
	panel(Rect2(198, 11, 120.0 * p.hp / 100, 11), Color("b77c73"))
	text("%d" % p.hp, 245, 20, 9)
	text("热量", 169, 40, 10)
	panel(Rect2(198, 31, 120, 7), Color("27353b"))
	panel(Rect2(198, 31, 120.0 * p.heat / 100, 7), Color("86b8af"))
	text("Q %d/60" % p.heat, 325, 39, 9, GOLD if p.heat >= 60 else MUTED)
	text("药瓶 %d" % p.potions, 341, 20, 10, GOLD)
	text("冲刺", 404, 20, 10)
	panel(Rect2(432, 12, 47, 6), Color("27353b"))
	panel(Rect2(432, 12, 47 * (1 - p.dash_cooldown / 0.6), 6), Color("8cb9b2"))
	text("第 %02d 波" % arena.wave, 509, 20, 11, GOLD)
	text("%02d:%02d  ·  击破 %d" % [int(arena.elapsed) / 60, int(arena.elapsed) % 60, p.kills], 509, 39, 9, MUTED)
	for i in range(5):
		var x = 18 + i * 122
		panel(Rect2(x, 59, 116, 24), Color("304044") if i == arena.lesson else Color("18242c"))
		if i == arena.lesson: panel(Rect2(x, 59, 116, 2), GOLD)
		text("%d  %s" % [i + 1, arena.LESSONS[i]], x + 8, 75, 11, GOLD if i == arena.lesson else MUTED)
	panel(Rect2(15, 100, 610, 44), Color(0.075, 0.115, 0.15, 0.95))
	text(arena.HINTS[arena.lesson], 25, 117, 10, GOLD)
	text("命中 %d   破势 %d   闪避 %d   下劈反弹 %d" % [p.hits, arena.breaks, p.dodges, p.bounces], 25, 134, 9, MUTED)
	text(p.last_action, 464, 134, 10, Color("a5c7bd"))
	panel(Rect2(0, 353, 640, 47), Color("0d151d"))
	text("A D 移动    空格 跳跃    S 下蹲    J 连击    ↑ J 上挑    空中 ↓ J 下劈", 18, 369, 10)
	text("L 重击    K 冲刺    Q 灯焰    R 喝药    ↓ 空格 穿平台", 18, 388, 10, GOLD)
	text("F1 说明 / ESC 暂停", 501, 388, 9, MUTED)
	if arena.debug_shapes:
		text("F2 判定框  ·  有效攻击为金色，受击区域为红/青色", 150, 344, 9, Color("89c6bb"))
	if arena.dead: draw_end()
	elif get_tree().paused:
		if arena.help_visible: draw_help()
		else: draw_pause()

func overlay(title: String, subtitle: String):
	panel(Rect2(0, 0, 640, 400), Color(0.025, 0.045, 0.065, 0.93))
	panel(Rect2(49, 55, 542, 290), Color("18262f"))
	panel(Rect2(49, 55, 542, 2), GOLD)
	text(title, 75, 94, 25, GOLD)
	text(subtitle, 75, 119, 11, MUTED)

func draw_help():
	overlay("巡灯人的剑术", "先辨认敌人的起手，再选择距离、方向和反击时机。")
	var lines = ["J 三段轻击：连续点按衔接，第三刀更重，后摇也更长。", "↑ J 上挑；空中 ↓ J 下劈，命中可反弹；L 重击更快破势。", "空格轻按短跳、按住满跳；S 下蹲躲高位弹，↓ 空格穿平台。", "K / Shift 冲刺中段短暂无敌，出手前摇不能随意取消。", "近战命中积攒热量；满 60 可按 Q 释放范围灯焰。", "R 喝药恢复 35；每场 1 瓶，动作中受击会打断并消耗药。", "1–5 或点击顶部切换练习；击破后自动开下一波。"]
	for i in range(lines.size()): text(lines[i], 75, 149 + i * 22, 11)
	text("F1 / ESC 继续    F2 判定框    F3 震动    F4 闪光    M 静音", 75, 325, 10, GOLD)

func draw_pause():
	overlay("暂歇片刻", "ESC 继续   ·   F1 动作说明   ·   1–5 切换练习")
	text("F3 画面震动：%s" % ("开启" if arena.feedback.shake_level > 0 else "关闭"), 78, 167, 14)
	text("F4 受击闪光：%s" % ("开启" if arena.feedback.flash_level > 0 else "关闭"), 78, 203, 14)
	text("M  音效：%s" % ("开启" if arena.feedback.sound_enabled else "关闭"), 78, 239, 14)
	text("F2 判定框    F6 像素素材 / 灰盒    F9 初版城镇", 78, 300, 11, GOLD)

func draw_end():
	overlay("灯还没有熄灭", "练习结束；调整一次应对，再试一次。")
	var p = arena.player
	text("%s · 第 %d 波" % [arena.LESSONS[arena.lesson], arena.wave], 79, 163, 15)
	text("命中 %d   击破 %d   破势 %d" % [p.hits, p.kills, arena.breaks], 79, 200, 13)
	text("闪避 %d   下劈反弹 %d   承受伤害 %d" % [p.dodges, p.bounces, p.damage_taken], 79, 231, 13)
	text("E 重新练习     1–5 换一种对手", 79, 295, 16, GOLD)
