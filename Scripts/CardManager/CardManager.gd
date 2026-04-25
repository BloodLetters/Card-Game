extends Node2D

var screen_size
var card_dragged
var drag_speed = 15.0
var is_hovering_on_card = false

func _ready() -> void:
	screen_size = get_viewport_rect().size

func _process(delta: float) -> void:
	if card_dragged:
		var mouse_pos = get_global_mouse_position()
		card_dragged.position = card_dragged.position.lerp(Vector2(
		clamp(mouse_pos.x, 0, screen_size.x),
		clamp(mouse_pos.y, 0, screen_size.y)
	),
	drag_speed * delta
)
		
func _input(event):
	if event is InputEventMouseButton and event.button_index == MOUSE_BUTTON_LEFT:
		if event.is_pressed():
			var card = raycard_check()
			if card:
				#card_dragged = card
				start_drag(card)
		else:
			#card_dragged = null
			finish_drag()

func connect_card_signal(card):
	card.connect("hovered", on_hovered_over_card)
	card.connect("hovered_off", on_hovered_off_card)

func start_drag(card):
	card_dragged = card
	card_dragged.scale = Vector2(1, 1)

func finish_drag():
	if card_dragged:
		card_dragged.scale = Vector2(1.05, 1.05)
		card_dragged = null

func on_hovered_over_card(card):
	if !is_hovering_on_card:
		is_hovering_on_card = true
		highlight_card(card, true)
	
func on_hovered_off_card(card):
	highlight_card(card, false)
	# check 
	var new_card_hovered = raycard_check()
	if new_card_hovered:
		highlight_card(new_card_hovered, true)
	else:
		is_hovering_on_card = false

func highlight_card(card, hovered):
	if hovered:
		card.scale = Vector2(1.05, 1.05)
		card.z_index = 2
	else:
		card.scale = Vector2(1, 1)
		card.z_index = 1

func raycard_check():
	var space_state = get_world_2d().direct_space_state
	var parameters = PhysicsPointQueryParameters2D.new()
	parameters.position = get_global_mouse_position()
	parameters.collide_with_areas = true
	parameters.collision_mask = 1
	var result = space_state.intersect_point(parameters)
	if result.size() > 0:
		#return result[0].collider.get_parent()
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
