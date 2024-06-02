@tool
class_name Airplane extends Node3D

# Consts
const BEGIN_LATITUDE := 55
const BEGIN_LONGITUDE := 37
const VERTICAL_OFFSET := 34
const STRETCH_COEF := 108000

# Utils
@export var loadData := false
@export var reload := false
@export var recordingActive := false

# Scene
@export var trajectory: TrajectoryLine

# UI
@export var rollValueLabel: Label
@export var pitchValueLabel: Label
@export var heightValueLabel: Label
@export var yawValueLabel: Label
@export var compass: Sprite2D

# Nav
var currentPoint: int = 0
var easingWindow: int = 5

var navRecords: Array[PackedStringArray]
var navCoordinates: Vector3 = Vector3(0.0, 0.0, 0.0)
var navVelocities: Vector3 = Vector3(0.0, 0.0, 0.0)
var navAngles: Vector3 = Vector3(0.0, 0.0, 0.0)
var yawNav: float = 0 : 
	get:
		return yawNav
	set(value):
		yawNav = value

func get_nav_velocities() -> Vector3:
	return navVelocities

func update_nav_data() -> void:
	# Note to self: east - +z, north - +x, up - +y
	var csvLine: PackedStringArray = navRecords[currentPoint]

	assert(csvLine.size() == 9, "INCORRECT FORMAT AT LINE " + str(currentPoint + 1))
	
	yawNav = -float(csvLine[2])
	# YXZ
	var angles := Vector3(
		-float(csvLine[0]),
		-(float(csvLine[2]) + 90),
		float(csvLine[1])
	)

	var velocs := Vector3(
		float(csvLine[1 + 3]),
		float(csvLine[2 + 3]),
		float(csvLine[0 + 3])
	)
	
	var coords := Vector3(
		(float(csvLine[0 + 3 * 2]) - BEGIN_LATITUDE) * STRETCH_COEF,
		float(csvLine[2 + 3 * 2]) + VERTICAL_OFFSET,
		(float(csvLine[1 + 3 * 2]) - BEGIN_LONGITUDE) * STRETCH_COEF,
	)
	
	var denom: int = currentPoint if currentPoint < easingWindow else easingWindow
	
	navAngles = (angles + denom * navAngles) / (denom + 1)
	navVelocities = (velocs + denom * navVelocities) / (denom + 1)
	navCoordinates = (coords + denom * navCoordinates) / (denom + 1)


func update_position() -> void:
	position = navCoordinates
	rotation_degrees = navAngles


func update_ui() -> void:
	rollValueLabel.text = str(rotation_degrees.z).pad_decimals(1) + "°"
	pitchValueLabel.text = str(rotation_degrees.x).pad_decimals(1) + "°"
	yawValueLabel.text = str(abs(yawNav)).pad_decimals(2) + "°"
	heightValueLabel.text = str(position.y).pad_decimals(2)

	compass.rotation_degrees = yawNav


func load_example(path: String) -> void:
	navRecords = []
	var recordsFile := FileAccess.open(path, FileAccess.READ)
	var line := recordsFile.get_csv_line()

	while line.size() == 9:	
		navRecords.append(line)
		line = recordsFile.get_csv_line()

	print("Loaded: ", str(navRecords.size()))
	print("First line: ", navRecords[0])


func toggle_movement() -> void:
	recordingActive = !recordingActive

func reset_movement() -> void:
	recordingActive = false
	currentPoint = 0
	
	if (navRecords):
		status_update()


func load_takeoff() -> void:
	load_example("res://data/takeoff_recording.csv")
	status_update()


func load_loop() -> void:
	load_example("res://data/loop_recording.csv")
	status_update()


func status_update() -> void:
	update_nav_data()
	update_position()
	trajectory.update()
	update_ui()


# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(_delta):  
	if loadData:
		load_example("res://data/loop_recording.csv")
		loadData = false

	if (recordingActive or reload) and navRecords:
		if reload:
			currentPoint = 0
			reload = false
			
		status_update()
		
		currentPoint += 1

		if currentPoint >= navRecords.size():
			recordingActive = false
