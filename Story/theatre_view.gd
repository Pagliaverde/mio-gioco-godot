## La platea: file di manichini, visti da dietro. Si disegna da sola.
##
## Tre regole, e non toccarle:
## [br]1. [b]Non si muovono mai.[/b] Ti fissano e basta.
## [br]2. [b]Non ti attaccano.[/b] Sono spettatori.
## [br]3. [b]Si girano tutti insieme, una volta sola.[/b] Alla fine: [method turn_all].
##
## E una cosa sola e' vera: [b]un manichino e' in un posto diverso ogni volta
## che torni[/b] ([method visit]). Nessun altro se ne accorge. Non fa niente.
## E' solo... spostato.
class_name TheatreView extends Control


## Quante file e quanti posti per fila.
@export var rows: int = 7
@export var seats_per_row: int = 16

## Il colore della sala.
@export var hall_color: Color = Color("1d1230")

## True quando i manichini si sono girati verso di te.
var turned: bool = false

## Il posto da cui manca il manichino che si sposta: (fila, posto).
var _empty_seat: Vector2i = Vector2i(-1, -1)

## Dove sta adesso: nel corridoio centrale, a questa fila (0 = la piu' lontana).
var _wanderer_row: int = -1

## Quante volte l'hai guardata.
var _visits: int = 0

## Il seme dei posti: cosi' il manichino si sposta sempre nello stesso modo
## a parita' di visita (e un salvataggio non lo rimette "a posto").
var _rng: RandomNumberGenerator = RandomNumberGenerator.new()


func _ready() -> void:
	mouse_filter = Control.MOUSE_FILTER_IGNORE
	resized.connect(queue_redraw)


## Imposta a quante visite siamo (per riprendere una partita salvata).
func set_visits(count: int) -> void:
	_visits = maxi(count, 0)
	_place_wanderer()
	queue_redraw()


## Torni a guardare la platea: il manichino e' in un altro posto.
func visit() -> int:
	_visits += 1
	_place_wanderer()
	queue_redraw()
	return _visits


## Quante volte l'hai guardata.
func visits() -> int:
	return _visits


## I manichini si girano. Tutti. Insieme. Una volta sola.
func turn_all() -> void:
	turned = true
	queue_redraw()


func _place_wanderer() -> void:
	if _visits <= 0:
		_empty_seat = Vector2i(-1, -1)
		_wanderer_row = -1
		return
	_rng.seed = 7919 * _visits + 17
	_empty_seat = Vector2i(_rng.randi_range(1, rows - 1), _rng.randi_range(0, seats_per_row - 1))
	_wanderer_row = _rng.randi_range(0, rows - 1)


func _draw() -> void:
	var w: float = size.x
	var h: float = size.y
	if w < 10.0 or h < 10.0:
		return

	# La sala: piu' scura in fondo, un filo di luce in basso (il palco e' dietro di te).
	draw_rect(Rect2(Vector2.ZERO, size), hall_color)
	var bands: int = 24
	for i: int in bands:
		var t: float = float(i) / float(bands)
		draw_rect(Rect2(0.0, h * t, w, h / float(bands) + 1.0), hall_color.lightened(t * 0.2))

	# Il corridoio centrale.
	var aisle_w: float = w * 0.07
	draw_rect(Rect2(w * 0.5 - aisle_w * 0.5, 0.0, aisle_w, h), hall_color.darkened(0.35))

	var top_margin: float = h * 0.08
	var row_gap: float = (h - top_margin - h * 0.04) / float(maxi(rows, 1))
	var half_seats: int = seats_per_row / 2
	var seat_w: float = (w * 0.5 - aisle_w * 0.5 - w * 0.03) / float(maxi(half_seats, 1))

	# La dimensione dei manichini segue la larghezza del posto, cosi' la platea
	# si riempie a qualsiasi dimensione della finestra.
	var unit: float = minf(seat_w, row_gap) / 20.0

	for row: int in rows:
		# Le file lontane sono piu' piccole e piu' scure: prospettiva povera, ma basta.
		var depth: float = float(row) / float(maxi(rows - 1, 1))
		var scale: float = lerpf(0.6, 1.0, depth) * unit
		var y: float = top_margin + row_gap * float(row) + row_gap * 0.62
		var shade: float = lerpf(0.5, 1.0, depth)

		for seat: int in seats_per_row:
			var side_index: int = seat if seat < half_seats else seat - half_seats
			var x: float
			if seat < half_seats:
				x = w * 0.03 + seat_w * (float(side_index) + 0.5)
			else:
				x = w * 0.5 + aisle_w * 0.5 + seat_w * (float(side_index) + 0.5)

			if Vector2i(row, seat) == _empty_seat:
				_draw_empty_seat(Vector2(x, y), scale, shade)
			else:
				_draw_mannequin(Vector2(x, y), scale, shade, turned)

		# Il manichino spostato: in piedi, nel corridoio.
		if row == _wanderer_row:
			_draw_mannequin(Vector2(w * 0.5, y - row_gap * 0.2), scale * 1.15, shade, turned)


## Un manichino visto da dietro: spalle e nuca. Girato: una faccia pallida
## con due buchi al posto degli occhi.
func _draw_mannequin(at: Vector2, scale: float, shade: float, facing_you: bool) -> void:
	var body: Color = Color(0.36, 0.30, 0.42).darkened(1.0 - shade)
	var head: Color = Color(0.52, 0.45, 0.50).darkened(1.0 - shade)
	var face: Color = Color(0.86, 0.82, 0.76).darkened(1.0 - shade)
	var ink: Color = Color(0.05, 0.03, 0.06)

	var shoulder: Vector2 = Vector2(16.0, 8.0) * scale
	var head_r: Vector2 = Vector2(5.0, 6.0) * scale

	draw_rect(Rect2(at - Vector2(shoulder.x * 0.5, 0.0), shoulder), body)
	draw_rect(Rect2(at - Vector2(shoulder.x * 0.5, 0.0), Vector2(shoulder.x, 1.5 * scale)), body.lightened(0.15))

	var head_center: Vector2 = at - Vector2(0.0, head_r.y * 0.7)
	_draw_oval(head_center, head_r, face if facing_you else head)
	draw_arc(head_center, head_r.x, 0.0, TAU, 16, ink, maxf(1.0, scale * 0.5))

	if facing_you:
		# Due buchi neri. Niente bocca: non parlano.
		var eye: Vector2 = Vector2(2.4, 1.8) * scale
		_draw_oval(head_center + Vector2(-2.6 * scale, -0.8 * scale), eye, ink)
		_draw_oval(head_center + Vector2(2.6 * scale, -0.8 * scale), eye, ink)
	else:
		# La luce della nuca.
		_draw_oval(head_center + Vector2(-1.5 * scale, -2.0 * scale), Vector2(2.0, 1.5) * scale, head.lightened(0.18))


func _draw_empty_seat(at: Vector2, scale: float, shade: float) -> void:
	var seat: Color = Color(0.30, 0.16, 0.22).darkened(1.0 - shade)
	var seat_size: Vector2 = Vector2(14.0, 8.0) * scale
	draw_rect(Rect2(at - Vector2(seat_size.x * 0.5, -1.0 * scale), seat_size), seat)
	draw_rect(Rect2(at - Vector2(seat_size.x * 0.5, 8.0 * scale), Vector2(seat_size.x, 9.0 * scale)), seat.darkened(0.25))


func _draw_oval(center: Vector2, radii: Vector2, color: Color) -> void:
	var points: PackedVector2Array = []
	for i: int in 14:
		var angle: float = TAU * float(i) / 14.0
		points.append(center + Vector2(cos(angle) * radii.x, sin(angle) * radii.y))
	draw_colored_polygon(points, color)
