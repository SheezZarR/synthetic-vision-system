@tool
class_name TrajectoryModel extends CSGPolygon3D

@export var dangerLabel: Label

class AlarmColor:
	const SAFE := Vector3(0.565, 0.933, 0.565)
	const DANGER := Vector3(1.0, 0.0, 0.0)

const SHADER_COLOR_PARAM_NAME := "albedoColor"


func update_color(intersectionTime: float) -> void:
	assert(material is ShaderMaterial, "ERROR: Line model is not using shader material!")
	var mat: ShaderMaterial = material

	if intersectionTime < 0:
		dangerLabel.text = ""
		mat.set_shader_parameter(SHADER_COLOR_PARAM_NAME, AlarmColor.SAFE)
		return
	
	if not dangerLabel:
		print("update_color::MISSING_DANGER_LABEL_TEXT!")
		return
	
	dangerLabel.text = "ОПАСНОСТЬ! ВРЕМЯ ДО СТОЛКНОВЕНИЯ " + str(intersectionTime) + " СЕКУНД!"

	mat.set_shader_parameter(SHADER_COLOR_PARAM_NAME, AlarmColor.DANGER)
	
	
	
