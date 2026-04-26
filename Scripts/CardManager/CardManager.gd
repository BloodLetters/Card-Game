extends Node2D

var screen_size
var card_dragged
var drag_speed = 15.0
var is_hovering_on_card = false

# Hand layout settings
@export var hand_center_offset = Vector2(0, 150)
@export var card_spacing = 160.0
@export var hover_lift = 30.0

func _ready() -> void:
	get_viewport().size_changed.connect(_on_viewport_size_changed)
	screen_size = get_viewport_rect().size
	update_hand_positions()

func _on_viewport_size_changed():
	screen_size = get_viewport_rect().size
	update_hand_positions()

func _process(delta: float) -> void:
	if card_dragged:
		if screen_size == null:
			screen_size = get_viewport_rect().size
			
		var mouse_pos = get_global_mouse_position()
		card_dragged.position = card_dragged.position.lerp(Vector2(
		clamp(mouse_pos.x, 0, screen_size.x),
		clamp(mouse_pos.y, 0, screen_size.y)
	),
	drag_speed * delta
)
	
	for card in get_children():
		if card != card_dragged and card.has_meta("target_pos"):
			var target_pos = card.get_meta("target_pos")
			var target_rot = card.get_meta("target_rot")
			card.position = card.position.lerp(target_pos, 10.0 * delta)
			card.rotation = lerp_angle(card.rotation, target_rot, 10.0 * delta)

func _input(event):
	if event is InputEventMouseButton and event.button_index == MOUSE_BUTTON_LEFT:
		if event.is_pressed():
			var card = raycard_check()
			if card:
				start_drag(card)
		else:
			finish_drag()

func connect_card_signal(card):
	card.connect("hovered", on_hovered_over_card)
	card.connect("hovered_off", on_hovered_off_card)
	
	# Simpan skala asli dari scene kartu
	if !card.has_meta("original_scale"):
		card.set_meta("original_scale", card.scale)
		
	update_hand_positions()

func start_drag(card):
	card_dragged = card
	if card.has_meta("original_scale"):
		card.scale = card.get_meta("original_scale")
	card_dragged.z_index = 10

func finish_drag():
	if card_dragged:
		if card_dragged.has_meta("original_scale"):
			card_dragged.scale = card_dragged.get_meta("original_scale") + Vector2(0.05, 0.05)
		card_dragged.z_index = 1
		card_dragged = null
		update_hand_positions()

func on_hovered_over_card(card):
	if !is_hovering_on_card:
		is_hovering_on_card = true
		highlight_card(card, true)
	
func on_hovered_off_card(card):
	highlight_card(card, false)
	var new_card_hovered = raycard_check()
	if new_card_hovered:
		highlight_card(new_card_hovered, true)
	else:
		is_hovering_on_card = false

func highlight_card(card, hovered):
	var base_scale = Vector2(1, 1)
	if card.has_meta("original_scale"):
		base_scale = card.get_meta("original_scale")
		
	if hovered:
		card.scale = base_scale + Vector2(0.1, 0.1) # Maksimal perbesar 0.1
		card.z_index = 5
		if card.has_meta("base_pos"):
			var lifted_pos = card.get_meta("base_pos") + Vector2(0, -hover_lift).rotated(card.get_meta("target_rot"))
			card.set_meta("target_pos", lifted_pos)
	else:
		card.scale = base_scale
		card.z_index = 1
		if card.has_meta("base_pos"):
			card.set_meta("target_pos", card.get_meta("base_pos"))

func update_hand_positions():
	var cards = get_children()
	var num_cards = cards.size()
	if num_cards == 0: return
	
	if screen_size == null:
		screen_size = get_viewport_rect().size

	# Hitung total lebar susunan kartu
	var total_width = (num_cards - 1) * card_spacing
	var start_x = screen_size.x / 2 - total_width / 2
	
	for i in range(num_cards):
		var card = cards[i]
		
		# Posisi global horizontal rata
		var global_pos = Vector2(start_x + (i * card_spacing), screen_size.y - hand_center_offset.y)
		var pos = to_local(global_pos)
		
		card.set_meta("base_pos", pos)
		card.set_meta("target_pos", pos)
		card.set_meta("target_rot", 0.0) # Tidak ada rotasi (rata)
		card.z_index = i

		if !card.has_meta("initialized"):
			card.position = pos
			card.rotation = 0.0
			card.set_meta("initialized", true)

func raycard_check():
	var space_state = get_world_2d().direct_space_state
	var parameters = PhysicsPointQueryParameters2D.new()
	parameters.position = get_global_mouse_position()
	parameters.collide_with_areas = true
	parameters.collision_mask = 1
	var result = space_state.intersect_point(parameters)
	if result.size() > 0:
		return get_card_with_heighest_z_index(result)
	return null

func get_card_with_heighest_z_index(cards):
	var heighest_z_card = cards[0].collider.get_parent()
	var heighest_z_index = heighest_z_card.z_index
	
	for i in range(1, cards.size()):
		var current_card = cards[i].collider.get_parent()
		if current_card.z_index > heighest_z_index:
			heighest_z_card = current_card
			heighest_z_index = current_card.z_index
	return heighest_z_card
