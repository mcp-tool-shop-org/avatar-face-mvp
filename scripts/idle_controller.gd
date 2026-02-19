## Procedural idle animation controller.
## Adds breathing, micro-sway, subtle spine movement, and head drift.
## Operates on Skeleton3D bones directly — additive on top of rest pose.
## Robust bone discovery handles VRM 0.x/1.0, ARKit, and VRChat rigs.
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

## Head micro-movement (subtle aliveness when no tracker active)
var head_drift_amplitude := 0.8  # Degrees
var head_drift_period := 6.0

## Shoulder breathing tie-in
var shoulder_breath_amplitude := 0.15  # Degrees — very subtle raise/lower

## Cached skeleton and bone indices
var _skeleton: Skeleton3D = null
var _head_idx := -1
var _neck_idx := -1
var _spine_idx := -1
var _chest_idx := -1
var _upper_chest_idx := -1
var _left_shoulder_idx := -1
var _right_shoulder_idx := -1
var _left_eye_idx := -1
var _right_eye_idx := -1
var _hips_idx := -1

## All bone names found (for debug)
var _bone_names: PackedStringArray = []

## Rest poses (captured once on setup)
var _head_rest := Quaternion.IDENTITY
var _neck_rest := Quaternion.IDENTITY

var _time := 0.0
var _active := false

## Perlin-ish drift state (accumulated random walk)
var _drift_offset := Vector3.ZERO
var _drift_target := Vector3.ZERO
var _drift_timer := 0.0
var _drift_interval := 4.0  # seconds between new targets
var _rng := RandomNumberGenerator.new()


## Common bone name variants across VRM formats
const BONE_ALIASES := {
	"Head": ["Head", "head", "J_Bip_C_Head", "head_x", "头"],
	"Neck": ["Neck", "neck", "J_Bip_C_Neck", "neck_x"],
	"Spine": ["Spine", "spine", "J_Bip_C_Spine", "spine_x"],
	"Chest": ["Chest", "chest", "J_Bip_C_Chest", "chest_x", "Spine1"],
	"UpperChest": ["UpperChest", "upperchest", "upper_chest", "J_Bip_C_UpperChest", "Spine2"],
	"Hips": ["Hips", "hips", "J_Bip_C_Hips", "hip", "Root"],
	"LeftShoulder": ["LeftShoulder", "leftshoulder", "left_shoulder", "J_Bip_L_Shoulder", "shoulder_L", "shoulder.L"],
	"RightShoulder": ["RightShoulder", "rightshoulder", "right_shoulder", "J_Bip_R_Shoulder", "shoulder_R", "shoulder.R"],
	"LeftEye": ["LeftEye", "lefteye", "left_eye", "J_Adj_L_FaceEye", "eye_L", "eye.L", "Eye_L"],
	"RightEye": ["RightEye", "righteye", "right_eye", "J_Adj_R_FaceEye", "eye_R", "eye.R", "Eye_R"],
}


## Set up with an avatar's Skeleton3D. Call once after avatar load.
func setup(avatar: Node3D):
	_skeleton = _find_skeleton(avatar)
	_active = false
	_drift_offset = Vector3.ZERO
	_drift_target = Vector3.ZERO
	_drift_timer = 0.0
	_rng.randomize()

	if _skeleton == null:
		push_warning("IdleController: no Skeleton3D found")
		return

	# Cache all bone names for alias search
	_bone_names.clear()
	for i in _skeleton.get_bone_count():
		_bone_names.append(_skeleton.get_bone_name(i))

	# Find bones using aliases
	_head_idx = _find_bone_aliased("Head")
	_neck_idx = _find_bone_aliased("Neck")
	_spine_idx = _find_bone_aliased("Spine")
	_chest_idx = _find_bone_aliased("Chest")
	_upper_chest_idx = _find_bone_aliased("UpperChest")
	_hips_idx = _find_bone_aliased("Hips")
	_left_shoulder_idx = _find_bone_aliased("LeftShoulder")
	_right_shoulder_idx = _find_bone_aliased("RightShoulder")
	_left_eye_idx = _find_bone_aliased("LeftEye")
	_right_eye_idx = _find_bone_aliased("RightEye")

	# Capture rest rotations for head/neck (used by apply_head_pose)
	if _head_idx >= 0:
		_head_rest = _skeleton.get_bone_pose_rotation(_head_idx)
	if _neck_idx >= 0:
		_neck_rest = _skeleton.get_bone_pose_rotation(_neck_idx)

	_active = _head_idx >= 0 or _spine_idx >= 0 or _chest_idx >= 0
	if _active:
		print("IdleController: active (head=%d, neck=%d, spine=%d, chest=%d, L_eye=%d, R_eye=%d)" % [
			_head_idx, _neck_idx, _spine_idx, _chest_idx, _left_eye_idx, _right_eye_idx])
	else:
		# Log available bones for debugging
		print("IdleController: INACTIVE — bones found: ", _bone_names)


func is_active() -> bool:
	return _active


func has_eye_bones() -> bool:
	return _left_eye_idx >= 0 and _right_eye_idx >= 0


func get_skeleton() -> Skeleton3D:
	return _skeleton


func get_eye_bone_indices() -> Vector2i:
	return Vector2i(_left_eye_idx, _right_eye_idx)


func get_head_bone_index() -> int:
	return _head_idx


## Call every frame. Applies procedural idle motion to bones.
func update(delta: float):
	if not _active or _skeleton == null:
		return

	_time += delta

	# Update Perlin-ish drift target
	_drift_timer += delta
	if _drift_timer >= _drift_interval:
		_drift_timer = 0.0
		_drift_interval = _rng.randf_range(3.0, 8.0)
		_drift_target = Vector3(
			_rng.randf_range(-0.5, 0.5),
			_rng.randf_range(-0.5, 0.5),
			_rng.randf_range(-0.2, 0.2)
		)
	# Smooth drift toward target
	_drift_offset = _drift_offset.lerp(_drift_target, delta * 0.4)

	# Breathing: subtle Y-scale pulse on chest/upper_chest
	var breath := sin(_time * TAU / breath_period)
	var breath_scale := 1.0 + breath * breath_amplitude

	if _chest_idx >= 0:
		_skeleton.set_bone_pose_scale(_chest_idx, Vector3(1.0, breath_scale, 1.0))

	if _upper_chest_idx >= 0:
		var uc_scale := 1.0 + breath * breath_amplitude * 0.5
		_skeleton.set_bone_pose_scale(_upper_chest_idx, Vector3(1.0, uc_scale, 1.0))

	# Shoulder breathing — subtle raise on inhale
	if shoulder_breath_amplitude > 0.0:
		var shoulder_angle := breath * deg_to_rad(shoulder_breath_amplitude)
		if _left_shoulder_idx >= 0:
			_skeleton.set_bone_pose_rotation(_left_shoulder_idx,
				Quaternion.from_euler(Vector3(0.0, 0.0, -shoulder_angle)))
		if _right_shoulder_idx >= 0:
			_skeleton.set_bone_pose_rotation(_right_shoulder_idx,
				Quaternion.from_euler(Vector3(0.0, 0.0, shoulder_angle)))

	# Micro-sway: subtle rotation on spine + drift noise
	if _spine_idx >= 0:
		var sway_x := sin(_time * TAU / sway_period_x) * deg_to_rad(sway_amplitude_x)
		var sway_z := sin(_time * TAU / sway_period_z) * deg_to_rad(sway_amplitude_z)
		sway_x += deg_to_rad(_drift_offset.x * 0.3)
		sway_z += deg_to_rad(_drift_offset.z * 0.2)
		var sway_rot := Quaternion.from_euler(Vector3(sway_x, 0.0, sway_z))
		_skeleton.set_bone_pose_rotation(_spine_idx, sway_rot)

	# Head micro-drift (only when no external head pose is active)
	# This is the default idle — apply_head_pose() overrides it when tracker is on
	if _head_idx >= 0:
		var drift_y := sin(_time * TAU / head_drift_period) * deg_to_rad(head_drift_amplitude)
		var drift_x := sin(_time * TAU / (head_drift_period * 1.3)) * deg_to_rad(head_drift_amplitude * 0.5)
		drift_y += deg_to_rad(_drift_offset.y * 0.8)
		drift_x += deg_to_rad(_drift_offset.x * 0.4)
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
		# Add subtle idle drift on top (reduced when tracking)
		var drift_y := sin(_time * TAU / head_drift_period) * deg_to_rad(head_drift_amplitude * 0.2)
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


## Apply eye bone rotation for gaze. Called by GazeController.
func apply_eye_rotation(left_euler: Vector3, right_euler: Vector3):
	if _skeleton == null:
		return
	if _left_eye_idx >= 0:
		_skeleton.set_bone_pose_rotation(_left_eye_idx, Quaternion.from_euler(left_euler))
	if _right_eye_idx >= 0:
		_skeleton.set_bone_pose_rotation(_right_eye_idx, Quaternion.from_euler(right_euler))


## Apply audio-driven micro head bob (subtle pitch from speech energy).
func apply_speech_head_bob(energy: float):
	if not _active or _skeleton == null or _head_idx < 0:
		return
	# Get current head rotation and add tiny pitch bob
	# energy is 0..1; max bob is ~2 degrees
	var bob_pitch := energy * deg_to_rad(2.0)
	var current := _skeleton.get_bone_pose_rotation(_head_idx)
	var bob := Quaternion.from_euler(Vector3(bob_pitch, 0.0, 0.0))
	_skeleton.set_bone_pose_rotation(_head_idx, current * bob)


func _find_skeleton(node: Node) -> Skeleton3D:
	if node is Skeleton3D:
		return node
	for child in node.get_children():
		var result := _find_skeleton(child)
		if result:
			return result
	return null


## Find bone by trying all known aliases for the canonical name.
func _find_bone_aliased(canonical: String) -> int:
	if _skeleton == null:
		return -1

	var aliases: Array = BONE_ALIASES.get(canonical, [canonical])

	# Try exact match first
	for alias in aliases:
		var idx := _skeleton.find_bone(alias)
		if idx >= 0:
			return idx

	# Try case-insensitive match against all bones
	var canonical_lower := canonical.to_lower()
	for alias in aliases:
		var alias_lower: String = alias.to_lower()
		for i in _bone_names.size():
			var bone_lower: String = _bone_names[i].to_lower()
			if bone_lower == alias_lower:
				return i

	# Try substring match for prefixed bones (e.g., "Armature/Head", "mixamorig:Head")
	for i in _bone_names.size():
		var bone_lower: String = _bone_names[i].to_lower()
		for alias in aliases:
			if bone_lower.ends_with(alias.to_lower()):
				return i

	return -1
