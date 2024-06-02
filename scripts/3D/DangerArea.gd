@tool
class_name DangerArea extends MeshInstance3D

@export var reload := false

@export var earthSurface: EarthSurface

@onready var prevTriangle: PackedVector3Array = PackedVector3Array(
	[
		Vector3(earthSurface.resolution, 0, 0),
		Vector3(0, 0, 0),
		Vector3(0, 0, earthSurface.resolution),
	]
)
var dangerIndices: PackedInt32Array = PackedInt32Array([])

func gen_indices() -> PackedInt32Array:
	# Must be clock-wise
	var idxs := PackedInt32Array([])
	
	for i in range(4 - 1):
		for j in range(4 - 1):
			var _tl: int = (i+1) * 4 + j 	 # top-left
			var _bl: int = i * 4 + j 		 # bottom-left
			var _br: int = i * 4 + (j+1) 	 # bottom-right
			var _tr: int = (i+1) * 4 + (j+1) # top-right

			# bottom triangle
			idxs.append(_tl)
			idxs.append(_br)
			idxs.append(_bl)
			
			# top triangle
			idxs.append(_tl)
			idxs.append(_tr)
			idxs.append(_br)

	return idxs

# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	dangerIndices = gen_indices()
	update(prevTriangle)


# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta: float) -> void:
	if reload:
		dangerIndices = gen_indices()
		update(prevTriangle)
		reload = false


func get_neighbors(dangerTriangleVertex: Vector3) -> PackedVector3Array:
	var allVerts := PackedVector3Array([])
	allVerts.resize(16)

	var startVertex := Vector3(
		dangerTriangleVertex.x - 2 * earthSurface.resolution,
		dangerTriangleVertex.y,
		dangerTriangleVertex.z - 1 * earthSurface.resolution
	)
	
	for i in range(4):
		for j in range(4):
			allVerts[i * 4 + j] = Vector3(
				startVertex.x + i * earthSurface.resolution,
				earthSurface.elevation_at(
					startVertex.x / earthSurface.resolution + i, 
					startVertex.z / earthSurface.resolution + j 
				) + 0.5,
				startVertex.z + j * earthSurface.resolution
			)

	return allVerts

func make_mesh() -> void:
	var arrMesh := ArrayMesh.new()
	
	var verticies := get_neighbors(prevTriangle[0])
	var arr := []
	arr.resize(Mesh.ARRAY_MAX)
	arr[Mesh.ARRAY_VERTEX] = verticies

	arr[Mesh.ARRAY_INDEX] = dangerIndices
	arrMesh.add_surface_from_arrays(Mesh.PRIMITIVE_TRIANGLES, arr)

	mesh = arrMesh
	

func update(baseTriangle: PackedVector3Array) -> void:
	if (baseTriangle.is_empty()):
		hide()
		return
	
	show()
	prevTriangle = baseTriangle
	make_mesh()
	

