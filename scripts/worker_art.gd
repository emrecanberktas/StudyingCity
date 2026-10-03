extends RefCounted
## İnşaat işçisi çizimi: baret, yelek, kollar ve yürüyen bacaklar.
## Asset kullanmadan kodla çiziliyor; s = karakterin birim boyu (toplam boy ~ 9s).

const PANTS := Color("33415c")
const BOOTS := Color("4a3426")
const SHIRT := Color("4f7cc4")
const STRIPE := Color("f2f2e6")
const HAT_DARK := Color("d9a400")
const BRICK := Color("b5523b")
const HAMMER_HEAD := Color("6b6b6b")
const HANDLE := Color("8a5a2b")

const SKINS := [Color("f1c27d"), Color("e0ac69"), Color("c68642"), Color("8d5524"), Color("ffdbac")]
const VESTS := [Color("ff8c1a"), Color("c6e03a"), Color("ff8c1a"), Color("f25c3a")]
const HATS := [Color("ffd23f"), Color("ffffff"), Color("ffd23f"), Color("ff8c1a")]
const HAIR := [Color("2b1b10"), Color("5a3a1e"), Color("111111"), Color("8b5a2b")]


## foot: ayakların ortası (yer). facing: 1 sağa, -1 sola bakar.
## step: yürüme döngüsü (radyan). pose: "walk", "carry" (başının üstünde tuğla) ya da "hammer".
static func draw(ci: CanvasItem, foot: Vector2, s: float, facing: int, step: float, pose: String, look: int) -> void:
	var skin: Color = SKINS[look % SKINS.size()]
	var vest: Color = VESTS[look % VESTS.size()]
	var hat: Color = HATS[look % HATS.size()]
	var hair: Color = HAIR[look % HAIR.size()]
	var f := float(facing)
	var w := maxf(1.5, s * 0.55)  # uzuv kalınlığı

	# Gölge
	_ellipse(ci, foot, Vector2(s * 1.6, s * 0.5), Color(0, 0, 0, 0.18))

	var walking := pose != "hammer"
	var swing := sin(step) * 0.5 if walking else 0.22  # çekiççi ayaklarını açıp sabit durur
	var bob := absf(sin(step)) * s * 0.25 if walking else 0.0
	var hip := foot + Vector2(0, -s * 3.6 - bob)
	var neck := hip + Vector2(0, -s * 3.0)
	var shoulder := neck + Vector2(0, s * 0.4)

	# Arkadaki bacak ve kol önce çizilir (daha koyu).
	_leg(ci, hip, s, -swing, f, w, PANTS.darkened(0.25), BOOTS.darkened(0.2))
	if pose == "walk":
		_arm(ci, shoulder, s, swing, f, w, SHIRT.darkened(0.25), skin.darkened(0.15))

	_leg(ci, hip, s, swing, f, w, PANTS, BOOTS)

	# Gövde: gömlek, yelek, reflektör şerit
	var torso := Rect2(hip + Vector2(-s * 1.0, -s * 3.0), Vector2(s * 2.0, s * 3.1))
	ci.draw_rect(torso, SHIRT)
	ci.draw_rect(Rect2(torso.position + Vector2(s * 0.15, s * 0.3), Vector2(s * 1.7, s * 2.6)), vest)
	ci.draw_rect(Rect2(torso.position + Vector2(s * 0.15, s * 1.6), Vector2(s * 1.7, s * 0.35)), STRIPE)

	# Baş: boyun, saç, yüz, göz, baret
	var head := neck + Vector2(f * s * 0.15, -s * 1.1)
	var hands := head + Vector2(0, -s * 2.2)
	if pose == "carry":
		# Kollar başın iki yanından yukarı uzanır, yüzü kapatmaz.
		ci.draw_line(shoulder + Vector2(-s * 0.8, 0), hands + Vector2(-s * 1.0, 0), SHIRT.darkened(0.15), w)
		ci.draw_line(shoulder + Vector2(s * 0.8, 0), hands + Vector2(s * 1.0, 0), SHIRT, w)
	ci.draw_rect(Rect2(neck + Vector2(-s * 0.3, -s * 0.4), Vector2(s * 0.6, s * 0.6)), skin.darkened(0.1))
	ci.draw_circle(head + Vector2(-f * s * 0.35, s * 0.1), s * 0.95, hair)  # ense, yüzün arkasında
	ci.draw_circle(head, s * 1.0, skin)
	ci.draw_circle(head + Vector2(f * s * 0.5, -s * 0.05), s * 0.16, Color("2b2b2b"))  # göz
	ci.draw_circle(head + Vector2(f * s * 1.0, s * 0.25), s * 0.22, skin.darkened(0.12))  # burun
	ci.draw_line(head + Vector2(f * s * 0.35, s * 0.55), head + Vector2(f * s * 0.75, s * 0.5), skin.darkened(0.35), maxf(1.0, s * 0.15))  # ağız
	_hard_hat(ci, head, s, f, hat)

	# Öndeki kol ve taşıdığı şey
	match pose:
		"carry":
			# Başının üstünde iki sıra tuğla
			ci.draw_rect(Rect2(hands + Vector2(-s * 1.5, -s * 1.0), Vector2(s * 3.0, s * 1.1)), BRICK)
			ci.draw_line(hands + Vector2(-s * 1.5, -s * 0.45), hands + Vector2(s * 1.5, -s * 0.45), BRICK.darkened(0.3), 1.0)
			ci.draw_circle(hands + Vector2(-s * 1.0, 0), s * 0.38, skin)
			ci.draw_circle(hands + Vector2(s * 1.0, 0), s * 0.38, skin)
		"hammer":
			# Kol yukarı kalkıp iner; çekiç ucu binaya vurur.
			var lift := (sin(step) * 0.5 + 0.5) * 1.6  # 0..1.6 radyan
			var dir := Vector2(f * cos(lift - 0.3), -sin(lift - 0.3))
			var hand := shoulder + dir * s * 2.3
			ci.draw_line(shoulder, hand, SHIRT, w)
			ci.draw_circle(hand, s * 0.35, skin)
			var tip := hand + dir.rotated(-f * 1.2) * s * 1.8
			ci.draw_line(hand, tip, HANDLE, maxf(1.0, w * 0.6))
			var head_dir := (tip - hand).normalized().orthogonal()
			ci.draw_line(tip - head_dir * s * 0.6, tip + head_dir * s * 0.6, HAMMER_HEAD, w * 1.2)
		_:
			_arm(ci, shoulder, s, -swing, f, w, SHIRT, skin)


static func _leg(ci: CanvasItem, hip: Vector2, s: float, angle: float, f: float, w: float, pants: Color, boot: Color) -> void:
	var knee := hip + Vector2(f * sin(angle) * s * 1.8, s * 1.8)
	var ankle := knee + Vector2(f * sin(angle * 0.5) * s * 1.6, s * 1.7)
	ci.draw_line(hip, knee, pants, w)
	ci.draw_line(knee, ankle, pants, w)
	ci.draw_rect(Rect2(ankle + Vector2(-s * 0.35 + (s * 0.2 if f > 0 else -s * 0.6), -s * 0.2), Vector2(s * 1.1, s * 0.55)), boot)


static func _arm(ci: CanvasItem, shoulder: Vector2, s: float, angle: float, f: float, w: float, sleeve: Color, skin: Color) -> void:
	var elbow := shoulder + Vector2(f * sin(angle) * s * 1.5, s * 1.4)
	var hand := elbow + Vector2(f * (sin(angle) * s * 1.0 + s * 0.4), s * 1.2)
	ci.draw_line(shoulder, elbow, sleeve, w)
	ci.draw_line(elbow, hand, sleeve, w)
	ci.draw_circle(hand, s * 0.35, skin)


static func _hard_hat(ci: CanvasItem, head: Vector2, s: float, f: float, color: Color) -> void:
	var top := head + Vector2(0, -s * 0.3)
	var dome := PackedVector2Array()
	for i in 13:
		var a := PI + PI * i / 12.0
		dome.append(top + Vector2(cos(a) * s * 1.15, sin(a) * s * 1.0))
	ci.draw_colored_polygon(dome, color)
	# Siper: baktığı yöne doğru uzanır
	ci.draw_rect(Rect2(top + Vector2(-s * 1.2 + (s * 0.1 if f > 0 else -s * 0.5), -s * 0.05), Vector2(s * 2.8, s * 0.35)), color.darkened(0.12))
	ci.draw_line(top + Vector2(0, -s * 1.0), top + Vector2(0, -s * 0.05), color.darkened(0.2), maxf(1.0, s * 0.2))


static func _ellipse(ci: CanvasItem, center: Vector2, radius: Vector2, color: Color) -> void:
	var points := PackedVector2Array()
	for i in 16:
		var a := TAU * i / 16.0
		points.append(center + Vector2(cos(a) * radius.x, sin(a) * radius.y))
	ci.draw_colored_polygon(points, color)
