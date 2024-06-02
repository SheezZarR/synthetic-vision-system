@tool
class_name EarthSurface extends Node3D

const OUT_OF_BOUNDS = 1000

@export var update := false

var heights: PackedFloat32Array
var resolution: int = 90 # meters between points

func get_resolution() -> int:
	return resolution

func get_arr() -> PackedFloat32Array:
	return heights

func elevation_at(x: int, z: int) -> float:
	# Z is east, X is north
	if (x * 1202 + z) > len(heights) or (x < 0) or (z < 0):
		return OUT_OF_BOUNDS

	return heights[x * 1202 + z]

func fill_vertex_array() -> void:
	heights.clear()
	var fileWithVerticies := FileAccess.open("res://data/vertex.csv", FileAccess.READ)
	
	var csvLine := fileWithVerticies.get_csv_line()

	for hght in csvLine:
		heights.push_back(float(hght))

	# print("Total number of heigth points: " + str(heights.size()))

func _ready() -> void:
	fill_vertex_array()

func _process(_delta: float) -> void:
	if update:
		fill_vertex_array()
		update = false
