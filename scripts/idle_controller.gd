## Procedural idle animation controller.
## Adds breathing, micro-sway, and subtle spine movement to kill T-pose stiffness.
## Operates on Skeleton3D bones directly — additive on top of rest pose.
class_name IdleController
extends RefCounted

## Breathing
var breath_amplitude := 0.003  # Y-scale oscillation on chest
var breath_period := 4.5  # Seconds per breath cycle

## Micro-sway (subtle upper body movement)
var sway_amplitude_x := 0.4  # Degrees
var sway_amplitude_z := 0.3  # Degrees
var sway_period_x := 7.0  # Seconds (slow, asymmetric)
var sway_period_z := 5.5

## Head micro-movement (subtle aliveness)
var head_drift_amplitude := 0.8  # Degrees
var head_drift_period := 6.0

## Cached skeleton and bone indices
var _skeleton: Skeleton3D = null
var _head_idx := -1
var _neck_idx := -1
var _spine_idx := -1
var _chest_idx := -1
var _upper_chest_idx := -1

## Rest poses (captured once on setup)
var _head_rest := Transform3D.IDENTITY
var _neck_rest := Transform3D.IDENTITY
var _spine_rest := Transform3D.IDENTITY
var _chest_rest := Transform3D.IDENTITY
var _upper_chest_rest := Transform3D.IDENTITY

var _time := 0.0
var _active := false


## Set up with an avatar's Skeleton3D. Call once after avatar load.
func setup(avatar: Node3D):
	_skeleton = _find_skeleton(avatar)
	_active = false
	if _skeleton == null:
		push_warning("IdleController: no Skeleton3D found")
		return

	# VRM humanoid bone names (standard)
	_head_idx = _find_bone("Head")
	_neck_idx = _find_bone("Neck")
	_spine_idx = _find_bone("Spine")
	_chest_idx = _find_bone("Chest")
	_upper_chest_idx = _find_bone("UpperChest")

	# Capture rest poses
	if _head_idx >= 0:
		_head_rest = _skeleton.get_bone_rest(_head_idx)
	if _neck_idx >= 0:
		_neck_rest = _skeleton.get_bone_rest(_neck_idx)
	if _spine_idx >= 0:
		_spine_rest = _skeleton.get_bone_rest(_spine_idx)
	if _chest_idx >= 0:
		_chest_rest = _skeleton.get_bone_rest(_chest_idx)
	if _upper_chest_idx >= 0:
		_upper_chest_rest = _skeleton.get_bone_rest(_upper_chest_idx)

	_active = _head_idx >= 0 or _spine_idx >= 0 or _chest_idx >= 0
	if _active:
		print("IdleController: active (head=%d, neck=%d, spine=%d, chest=%d)" % [
			_head_idx, _neck_idx, _spine_idx, _chest_idx])


func is_active() -> bool:
	return _active


## Call every frame. Applies procedural idle motion to bones.
func update(delta: float):
	if not _active or _skeleton == null:
		return

	_time += delta

	# Breathing: subtle Y-scale pulse on chest/upper_chest
	var breath := sin(_time * TAU / breath_period)
	var breath_scale := 1.0 + breath * breath_amplitude

	if _chest_idx >= 0:
		var t := _chest_rest
		t = t.scaled_local(Vector3(1.0, breath_scale, 1.0))
		_skeleton.set_bone_pose_position(_chest_idx, t.origin)
		_skeleton.set_bone_pose_scale(_chest_idx, Vector3(1.0, breath_scale, 1.0))

	if _upper_chest_idx >= 0:
		var uc_scale := 1.0 + breath * breath_amplitude * 0.5
		_skeleton.set_bone_pose_scale(_upper_chest_idx, Vector3(1.0, uc_scale, 1.0))

	# Micro-sway: subtle rotation on spine
	if _spine_idx >= 0:
		var sway_x := sin(_time * TAU / sway_period_x) * deg_to_rad(sway_amplitude_x)
		var sway_z := sin(_time * TAU / sway_period_z) * deg_to_rad(sway_amplitude_z)
		var sway_rot := Quaternion.from_euler(Vector3(sway_x, 0.0, sway_z))
		_skeleton.set_bone_pose_rotation(_spine_idx, sway_rot)

	# Head micro-drift: very subtle movement for aliveness
	if _head_idx >= 0:
		var drift_y := sin(_time * TAU / head_drift_period) * deg_to_rad(head_drift_amplitude)
		var drift_x := sin(_time * TAU / (head_drift_period * 1.3)) * deg_to_rad(head_drift_amplitude * 0.5)
		var drift_rot := Quaternion.from_euler(Vector3(drift_x, drift_y, 0.0))
		_skeleton.set_bone_pose_rotation(_head_idx, drift_rot)


## Apply external head rotation (from OpenSeeFace), blended with idle.
## rotation_degrees: Vector3 of pitch, yaw, roll in degrees.
## Splits 70% head, 30% neck. Clamps to human range.
func apply_head_pose(rotation_degrees: Vector3):
	if not _active or _skeleton == null:
		return

	# Clamp to human range
	var pitch := clampf(rotation_degrees.x, -20.0, 20.0)
	var yaw := clampf(rotation_degrees.y, -35.0, 35.0)
	var roll := clampf(rotation_degrees.z, -15.0, 15.0)

	# Head gets 70%
	if _head_idx >= 0:
		var head_euler := Vector3(
			deg_to_rad(pitch * 0.7),
			deg_to_rad(yaw * 0.7),
			deg_to_rad(roll * 0.7)
		)
		# Add idle drift on top
		var drift_y := sin(_time * TAU / head_drift_period) * deg_to_rad(head_drift_amplitude * 0.3)
		head_euler.y += drift_y
		_skeleton.set_bone_pose_rotation(_head_idx, Quaternion.from_euler(head_euler))

	# Neck gets 30%
	if _neck_idx >= 0:
		var neck_euler := Vector3(
			deg_to_rad(pitch * 0.3),
			deg_to_rad(yaw * 0.3),
			deg_to_rad(roll * 0.3)
		)
		_skeleton.set_bone_pose_rotation(_neck_idx, Quaternion.from_euler(neck_euler))


func _find_skeleton(node: Node) -> Skeleton3D:
	if node is Skeleton3D:
		return node
	for child in node.get_children():
		var result := _find_skeleton(child)
		if result:
			return result
	return null


func _find_bone(bone_name: String) -> int:
	if _skeleton == null:
		return -1
	var idx := _skeleton.find_bone(bone_name)
	if idx >= 0:
		return idx
	# Try lowercase
	for i in _skeleton.get_bone_count():
		if _skeleton.get_bone_name(i).to_lower() == bone_name.to_lower():
			return i
	return -1
