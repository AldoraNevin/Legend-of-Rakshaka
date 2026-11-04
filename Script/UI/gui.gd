extends CanvasLayer

const HEART_ROW_SIZE = 8
const HEART_OFFSET = 16

# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	for i in player_data.max_life:
		var new_heart = Sprite2D.new()
		new_heart.texture = $heart.texture
		new_heart.hframes = $heart.hframes
		$heart.add_child(new_heart)


# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(_delta: float) -> void:
	$coin_number.text = var_to_str(player_data.coin)
	display_heart()

func display_heart():
	_sync_heart_count()
	for heart in $heart.get_children():
		var index = heart.get_index()
		var x = (index % HEART_ROW_SIZE) * HEART_OFFSET
		var y = floori(float(index) / HEART_ROW_SIZE) * HEART_OFFSET
		heart.position = Vector2(x, y)
		
		var last_heart = floor(player_data.life)
		if index > last_heart:
			heart.frame = 0
		if index == last_heart:
			heart.frame = (player_data.life - last_heart) * 4
		if index < last_heart:
			heart.frame = 4


func _sync_heart_count() -> void:
	while $heart.get_child_count() < player_data.max_life:
		var new_heart = Sprite2D.new()
		new_heart.texture = $heart.texture
		new_heart.hframes = $heart.hframes
		$heart.add_child(new_heart)
