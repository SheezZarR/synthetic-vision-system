@tool
class_name TrajectoryLine extends Path3D

const TAG := "DEBUG: "
const EPSILOH = 0.000001
const DENOM_ZERO = 80000
var destination := Vector3(0.1, 0.1, 0.1)

# Utils
@export var reload := false
@export var timeHorizon := 100

# 3D
@export var lineModel: TrajectoryModel
@export var airplane: Airplane
@export var earthSufrace: EarthSurface
@export var dangerArea: DangerArea


func adjust(toMap: float, low: float, top: float) -> float:
	return (toMap - low) / (top - low)

func closest_surface_verticies(vert: Vector3) -> Array[Vector3]:
	var resolution := earthSufrace.get_resolution()

	# Scaling down to get good coords
	var xLow := floori(vert.x / resolution) 
	var xHigh := ceili(vert.x / resolution)
	var zLow := floori(vert.z / resolution)
	var zHigh := ceili(vert.z / resolution)
	
	var bottom_left := Vector3(xLow * resolution, earthSufrace.elevation_at(xLow, zLow), zLow * resolution)
	var top_left := Vector3(xHigh * resolution, earthSufrace.elevation_at(xHigh, zLow), zLow * resolution)
	var bottom_right := Vector3(xLow * resolution, earthSufrace.elevation_at(xLow, zHigh), zHigh * resolution)
	var top_right := Vector3(xHigh * resolution, earthSufrace.elevation_at(xHigh, zHigh), zHigh * resolution)
	
	var output: Array[Vector3] = []

	if -adjust(vert.z, zLow, zHigh) + 1 > adjust(vert.x, xLow, xHigh):
		output = [top_left, bottom_left, bottom_right]
	else:
		output = [top_left, bottom_right, top_right]	

	return output

func surface_height_at(vert: Vector3, surfVerts: PackedVector3Array) -> float:
	var numerator: float = (
		(vert.x - surfVerts[0].x) * ((surfVerts[1].y - surfVerts[0].y) * (surfVerts[2].z - surfVerts[0].z) - (surfVerts[2].y - surfVerts[0].y) * (surfVerts[1].z - surfVerts[0].z)) +
		(vert.z - surfVerts[0].z) * ((surfVerts[1].x - surfVerts[0].x) * (surfVerts[2].y - surfVerts[0].y) - (surfVerts[2].x - surfVerts[0].x) * (surfVerts[1].y - surfVerts[0].y))
	)
	var denominator: float = ((surfVerts[1].x - surfVerts[0].x) * (surfVerts[2].z - surfVerts[0].z) - (surfVerts[2].x - surfVerts[0].x) * (surfVerts[1].z - surfVerts[0].z))

	if (denominator == 0):
		print("get_closest_surface::DENOMINATOR IS 0!")
		return DENOM_ZERO

	return (surfVerts[0].y - numerator / denominator)
	

class AffectedArea:
	var time: float
	var triangle: PackedVector3Array

	func _init() -> void:
		self.time = -1
		self.triangle = []


func get_intersection() -> AffectedArea:
	var airplaneVel := airplane.get_nav_velocities()
	var posAlongPath := airplane.global_position + Vector3(0.0, 0.0, 0.0) 
	var output := AffectedArea.new()

	for i in range(0, timeHorizon + 1):
		posAlongPath += airplaneVel
		
		var surfVerts := closest_surface_verticies(posAlongPath)
		var surfHeight := surface_height_at(posAlongPath, surfVerts)
		
		if (surfHeight == DENOM_ZERO):
			continue
		
		if (posAlongPath.y - surfHeight) <= EPSILOH:
			output.time = i
			output.triangle = surfVerts

			return output
	
	return output

func update() -> void:
	var airplaneVel := airplane.get_nav_velocities()

	destination = Vector3(
		timeHorizon * airplaneVel.x / 10,
		timeHorizon * airplaneVel.y / 10,
		timeHorizon * airplaneVel.z / 10
	)

	if destination.length() < EPSILOH:
		destination = Vector3(0.01, 0.01, 0.01)

	curve.set_point_position(1, to_local(global_position + destination))

	var intersectionData := get_intersection()
	lineModel.update_color(intersectionData.time)
	dangerArea.update(intersectionData.triangle)
