extends TileMapLayer

var TILE_SIZE = 64
var playing = false

@export var width:int
@export var height:int

var temp_state # 棋盘状态
var changing = true # 检测是否进入静态

var cam: Camera2D
var zoom_level = 2.0  #  默认缩放级别

var drag_start: Vector2
var dragging = false # 检测拖拽镜头 

func _ready() -> void:
	var width_px = width * TILE_SIZE
	var height_px = height * TILE_SIZE
	
	cam = $Camera2D
	
	# 设置相机位置到网格中心
	cam.position = Vector2(width_px, height_px) / 2
	var viewport_size = get_viewport().get_visible_rect().size
	cam.zoom = Vector2(width_px, height_px) / Vector2(viewport_size[0], viewport_size[1])
	

	reset_grid()
	
# 初始化网格状态	
func reset_grid():
	temp_state = []
	for x in range(width):
		var temp = []
		for y in range(height):
			# tilemap坐标+图集id+图集坐标
			set_cell(Vector2i(x, y), 0, Vector2i(0, 0))  # 设置所有单元格为“死亡”
			temp.append(0)  # 将单元格状态存入temp数组
		temp_state.append(temp)  # 将temp数组存入主状态数组

# 处理输入事件（包括相机控制）
func _input(event: InputEvent) -> void:
	# 切换播放状态
	if event.is_action_pressed("Play"):
		playing = !playing
		Life.playing = !Life.playing
	
	# 检测鼠标点击来翻转单元格状态
	if event.is_action_pressed("Click"):
		var pos = (get_local_mouse_position() / TILE_SIZE).floor()
		set_cell(pos, 1 - get_cell_source_id(pos), Vector2i(0, 0))
	
	# 缩放视角（鼠标滚轮）
	if event.is_action_pressed("Zoom Out"):
		zoom_camera(0.9)  # 缩小
	if event.is_action_pressed("Zoom In"):
		zoom_camera(1.1)  # 放大
	
	# 重置网格
	if event.is_action_pressed("Reset"):
		reset_grid()
	
	# 拖拽视角（鼠标移动）
	if event.is_action_pressed("Move"):
		dragging = true
	elif event.is_action_released("Move"):
		dragging = false
	# 开始拖拽
	if event is InputEventMouseMotion and dragging:
		cam.position -= event.relative * cam.zoom / zoom_level  # 根据鼠标移动量和当前缩放调整相机位置



# 相机缩放函数
func zoom_camera(factor: float) -> void:
	zoom_level *= factor
	zoom_level = clamp(zoom_level, 0.5, 10.0)  # 限制缩放级别范围
	cam.zoom = Vector2(zoom_level, zoom_level)

# 在每帧中更新网格
func _process(_delta: float) -> void:
	update_field()
	if playing and changing: 
		Life.iteration += 1

# 更新整个网格状态的逻辑
func update_field():
	# 如果游戏处于暂停状态，则不进行更新
	if not playing:
		return
	
	changing = false
	# 遍历网格中的每个单元格
	for x in range(width):
		for y in range(height):
			var live_neighbours = 0
			# 检查每个单元格的8个邻居
			for xi in [-1, 0, 1]:
				for yi in [-1, 0, 1]:
					# 确保不检查自身
					if xi != yi or xi != 0:
						# 如果邻居是活的，计数器加1
						if get_cell_source_id(Vector2i(x + xi, y + yi)) == 1:
							live_neighbours += 1
			# 根据Game of Life规则更新当前单元格的状态
			if get_cell_source_id(Vector2i(x, y)) == 1:  # 当前单元格是活的
				if live_neighbours in [2, 3]:  # 有2或3个活邻居则保持存活
					temp_state[x][y] = 1				
				else:  # 否则单元格死亡
					temp_state[x][y] = 0
					changing = true
			elif get_cell_source_id(Vector2i(x, y)) == 0:  # 当前单元格是死的
				if live_neighbours == 3:  # 有恰好3个活邻居则复活
					temp_state[x][y] = 1
					changing = true
				else:
					temp_state[x][y] = 0
	
	# 更新TileMap中的状态
	for x in range(width):
		for y in range(height):
			# 更新TileMap中所有单元格的状态，tilemap坐标+图集id+图集坐标
			set_cell(Vector2i(x, y), temp_state[x][y], Vector2i(0, 0))
