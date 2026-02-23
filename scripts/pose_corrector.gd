## Runtime pose corrector for VRM avatars.
## Applies arm-down rotation every frame via set_bone_pose_rotation().
## This works alongside spring bones (which only affect hair/tail/skirt, not arms).
##
## Attach as a child of the avatar. Call setup() after avatar is in the scene tree.
class_name PoseCorrector
extends Node

## Bone alias lookup — same convention as IdleController.
const BONE_ALIASES := {
	"LeftUpperArm":
	[
		"LeftUpperArm",
		"leftupperarm",
		"left_upper_arm",
		"J_Bip_L_UpperArm",
		"upper_arm.L",
		"upperarm_L",
		"mixamorig:LeftArm"
	],
	"RightUpperArm":
	[
		"RightUpperArm",
		"rightupperarm",
		"right_upper_arm",
		"J_Bip_R_UpperArm",
		"upper_arm.R",
		"upperarm_R",
		"mixamorig:RightArm"
	],
	"LeftLowerArm":
	[
		"LeftLowerArm",
		"leftlowerarm",
		"left_lower_arm",
		"J_Bip_L_LowerArm",
		"lower_arm.L",
		"lowerarm_L",
		"mixamorig:LeftForeArm"
	],
	"RightLowerArm":
	[
		"RightLowerArm",
		"rightlowerarm",
		"right_lower_arm",
		"J_Bip_R_LowerArm",
		"lower_arm.R",
		"lowerarm_R",
		"mixamorig:RightForeArm"
	],
}

## Whether correction is active
var corrected := false
var correction_details := ""

## Cached bone indices and correction quaternions
var _skel: Skeleton3D = null
var _left_upper_idx := -1
var _right_upper_idx := -1
var _left_correction := Quaternion.IDENTITY
var _right_correction := Quaternion.IDENTITY


func _ready():
	set_process(false)  # Don't process until setup() is called


## Call after avatar is added to the scene tree.
## Detects T-pose arms and computes correction quaternions.
func setup(avatar: Node3D) -> bool:
	set_process(false)
	corrected = false
	correction_details = ""
	_skel = null
	_left_upper_idx = -1
	_right_upper_idx = -1
	_left_correction = Quaternion.IDENTITY
	_right_correction = Quaternion.IDENTITY

	_skel = _find_skeleton(avatar)
	if _skel == null:
		correction_details = "No Skeleton3D found"
		return false

	var bone_names: PackedStringArray = []
	for i in _skel.get_bone_count():
		bone_names.append(_skel.get_bone_name(i))

	var lu := _find_bone(_skel, bone_names, "LeftUpperArm")
	var ru := _find_bone(_skel, bone_names, "RightUpperArm")
	var ll := _find_bone(_skel, bone_names, "LeftLowerArm")
	var rl := _find_bone(_skel, bone_names, "RightLowerArm")

	if lu < 0 and ru < 0:
		correction_details = "No arm bones found"
		return false

	var details := []

	# Compute correction for left arm
	if lu >= 0 and _arm_needs_fix(_skel, lu, ll):
		_left_upper_idx = lu
		_left_correction = _compute_correction(_skel, lu, ll, true)
		details.append("left")
		print("PoseCorrector: L arm correction = %s" % _left_correction)

	# Compute correction for right arm
	if ru >= 0 and _arm_needs_fix(_skel, ru, rl):
		_right_upper_idx = ru
		_right_correction = _compute_correction(_skel, ru, rl, false)
		details.append("right")
		print("PoseCorrector: R arm correction = %s" % _right_correction)

	if details.is_empty():
		correction_details = "Arms already down"
		return false

	corrected = true
	correction_details = "%s arm(s) corrected" % " + ".join(details)
	print("PoseCorrector: %s" % correction_details)

	# Apply once immediately, then keep applying every frame
	_apply_corrections()
	set_process(true)
	return true


func _process(_delta: float):
	if _skel and is_instance_valid(_skel):
		_apply_corrections()
	else:
		set_process(false)


func _apply_corrections():
	if _left_upper_idx >= 0:
		_skel.set_bone_pose_rotation(_left_upper_idx, _left_correction)
	if _right_upper_idx >= 0:
		_skel.set_bone_pose_rotation(_right_upper_idx, _right_correction)


## Check if arm is NOT hanging down (T-pose or any non-downward direction).
func _arm_needs_fix(skel: Skeleton3D, upper_idx: int, lower_idx: int) -> bool:
	if upper_idx < 0:
		return false

	var upper_rest := skel.get_bone_global_rest(upper_idx)

	if lower_idx >= 0:
		var lower_rest := skel.get_bone_global_rest(lower_idx)
		var arm_dir := (lower_rest.origin - upper_rest.origin).normalized()
		print("PoseCorrector: arm dir=%s downness=%.3f" % [arm_dir, arm_dir.dot(Vector3.DOWN)])
		return arm_dir.dot(Vector3.DOWN) < 0.5
	else:
		return upper_rest.basis.y.normalized().dot(Vector3.DOWN) < 0.5


## Compute the pose rotation that brings the arm from T-pose to A-pose.
##
## Strategy: brute-force search. Try 26 candidate rotations (6 cardinal axes
## × several angles), temporarily apply each via set_bone_pose_rotation(),
## read the ACTUAL resulting global position of the lower arm bone, and pick
## whichever gets the arm direction closest to the target. No math assumptions
## about bone-local axis conventions — just measure what Godot actually does.
func _compute_correction(
	skel: Skeleton3D, upper_idx: int, lower_idx: int, is_left: bool
) -> Quaternion:
	if lower_idx < 0:
		return Quaternion.IDENTITY

	# Current arm direction from rest poses (no pose applied)
	skel.set_bone_pose_rotation(upper_idx, Quaternion.IDENTITY)
	skel.reset_bone_pose(upper_idx)
	var rest_upper_pos := skel.get_bone_global_rest(upper_idx).origin
	var rest_lower_pos := skel.get_bone_global_rest(lower_idx).origin
	var cur_dir := (rest_lower_pos - rest_upper_pos).normalized()

	# Target direction
	var side := 1.0 if is_left else -1.0
	var target_dir := Vector3(side * 0.22, -0.95, 0.0).normalized()

	# Angles to try (in degrees)
	var test_angles := [30.0, 50.0, 70.0, 90.0, 110.0]
	# Axes to try
	var test_axes := [
		Vector3(1, 0, 0),
		Vector3(-1, 0, 0),
		Vector3(0, 1, 0),
		Vector3(0, -1, 0),
		Vector3(0, 0, 1),
		Vector3(0, 0, -1),
	]

	var best_quat := Quaternion.IDENTITY
	var best_dot := -999.0

	for axis in test_axes:
		for angle_deg in test_angles:
			var q := Quaternion(axis, deg_to_rad(angle_deg))
			skel.set_bone_pose_rotation(upper_idx, q)

			# Force skeleton to update and read actual posed global positions
			# get_bone_global_pose returns the final posed transform in skeleton space
			var posed_upper := skel.to_global(skel.get_bone_global_pose(upper_idx).origin)
			var posed_lower := skel.to_global(skel.get_bone_global_pose(lower_idx).origin)
			var posed_dir := (posed_lower - posed_upper).normalized()
			var score := posed_dir.dot(target_dir)

			if score > best_dot:
				best_dot = score
				best_quat = q

	# Reset and report
	skel.set_bone_pose_rotation(upper_idx, Quaternion.IDENTITY)

	# Verify the winner
	skel.set_bone_pose_rotation(upper_idx, best_quat)
	var verify_upper := skel.to_global(skel.get_bone_global_pose(upper_idx).origin)
	var verify_lower := skel.to_global(skel.get_bone_global_pose(lower_idx).origin)
	var verify_dir := (verify_lower - verify_upper).normalized()
	skel.set_bone_pose_rotation(upper_idx, Quaternion.IDENTITY)

	print(
		(
			"PoseCorrector: %s arm: cur=%s target=%s best=%s (dot=%.3f)"
			% ["L" if is_left else "R", cur_dir, target_dir, verify_dir, best_dot]
		)
	)

	return best_quat


## Compute quaternion that rotates direction a to direction b.
func _quat_from_to(a: Vector3, b: Vector3) -> Quaternion:
	var v0 := a.normalized()
	var v1 := b.normalized()
	var d := v0.dot(v1)

	if d > 0.9999:
		return Quaternion.IDENTITY

	if d < -0.9999:
		var axis := v0.cross(Vector3.RIGHT)
		if axis.length_squared() < 0.001:
			axis = v0.cross(Vector3.UP)
		return Quaternion(axis.normalized(), PI)

	var axis := v0.cross(v1)
	var s := sqrt((1.0 + d) * 2.0)
	var inv_s := 1.0 / s
	return Quaternion(axis.x * inv_s, axis.y * inv_s, axis.z * inv_s, s * 0.5).normalized()


func _find_skeleton(node: Node) -> Skeleton3D:
	if node is Skeleton3D:
		return node
	for child in node.get_children():
		var result := _find_skeleton(child)
		if result:
			return result
	return null


func _find_bone(skel: Skeleton3D, bone_names: PackedStringArray, canonical: String) -> int:
	var aliases: Array = BONE_ALIASES.get(canonical, [canonical])

	for alias in aliases:
		var idx := skel.find_bone(alias)
		if idx >= 0:
			return idx

	for alias in aliases:
		var alias_lower: String = alias.to_lower()
		for i in bone_names.size():
			if bone_names[i].to_lower() == alias_lower:
				return i

	for i in bone_names.size():
		var bone_lower: String = bone_names[i].to_lower()
		for alias in aliases:
			if bone_lower.ends_with(alias.to_lower()):
				return i

	return -1
