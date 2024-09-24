extends CanvasLayer


# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(_delta: float) -> void:
	$TopLeft/Iteration.text = str(Life.iteration)
	if Life.playing: 
		$TopMid/Paused.visible = false
	else:
		$TopMid/Paused.visible = true
