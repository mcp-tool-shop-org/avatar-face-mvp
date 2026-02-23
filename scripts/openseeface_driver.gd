## OpenSeeFace UDP driver.
## Receives face tracking data via UDP (default localhost:11573) and maps
## ARKit-ish blendshapes to our driver weight format.
##
## Protocol: OpenSeeFace sends binary packets with 68 landmarks + blendshapes.
## We parse the subset we need: visemes (jaw/mouth shapes) + expressions + head pose.
##
## Usage: create instance, call start(), poll get_viseme_weights() / get_expression_weights()
## each frame. Call stop() when done.
class_name OpenSeeFaceDriver
extends RefCounted

## OpenSeeFace default output port
var host := "127.0.0.1"
var port := 11573

## ARKit blendshape name -> our driver weight name mapping
## OpenSeeFace outputs a subset of ARKit-compatible blend shapes
const ARKIT_TO_VISEME := {
	"jawOpen": "aa",
	"mouthFunnel": "ou",
	"mouthPucker": "oh",
	"mouthSmile_L": "ih",  # approximation: smile ≈ wide mouth ≈ ih/ee
	"mouthSmile_R": "ih",
	"mouthWide": "ee",
}

const ARKIT_TO_EXPRESSION := {
	"eyeBlink_L": "blink_left",
	"eyeBlink_R": "blink_right",
	"mouthSmile_L": "happy",
	"mouthSmile_R": "happy",
	"browDown_L": "angry",
	"browDown_R": "angry",
	"browInnerUp": "sad",
	"eyeWide_L": "surprised",
	"eyeWide_R": "surprised",
}

## Head rotation (Euler degrees) from tracker
var head_rotation := Vector3.ZERO

## Raw ARKit weights from last packet
var _raw_weights: Dictionary = {}

## Parsed driver weights (reused to avoid per-frame alloc)
var _viseme_weights: Dictionary = {
	"aa": 0.0,
	"ih": 0.0,
	"ou": 0.0,
	"ee": 0.0,
	"oh": 0.0,
}
var _expression_weights: Dictionary = {
	"blink_left": 0.0,
	"blink_right": 0.0,
	"happy": 0.0,
	"sad": 0.0,
	"angry": 0.0,
	"surprised": 0.0,
}

var _udp: PacketPeerUDP = null
var _active := false


func start() -> Error:
	if _active:
		return OK
	_udp = PacketPeerUDP.new()
	var err := _udp.bind(port, host)
	if err != OK:
		push_error("OpenSeeFace: failed to bind UDP %s:%d — error %d" % [host, port, err])
		_udp = null
		return err
	_active = true
	print("OpenSeeFace: listening on %s:%d" % [host, port])
	return OK


func stop():
	if _udp:
		_udp.close()
		_udp = null
	_active = false


func is_active() -> bool:
	return _active


## Call once per frame to drain UDP buffer and update weights.
func poll():
	if not _active or _udp == null:
		return

	# Drain all pending packets, keep only the latest
	var latest_data: PackedByteArray = PackedByteArray()
	while _udp.get_available_packet_count() > 0:
		latest_data = _udp.get_packet()

	if latest_data.size() == 0:
		return

	_parse_packet(latest_data)


## Parse OpenSeeFace binary packet.
## Packet format (simplified):
##   Bytes 0-3: face ID (int32)
##   Bytes 4-7: width (float)
##   Bytes 8-11: height (float)
##   Bytes 12-23: right eye 3D (3x float)
##   Bytes 24-35: left eye 3D (3x float)
##   Bytes 36-59: rotation quaternion (4x float) + ???
##   ... then 68 landmarks (68 x 2 floats = 544 bytes)
##   ... then features/blendshapes at the tail
##
## The actual format depends on OpenSeeFace version. We use a pragmatic approach:
## look for the blendshape block which starts after fixed-size header + landmarks.
func _parse_packet(data: PackedByteArray):
	# OpenSeeFace v1.x packet: header is variable but blendshapes are at known offsets
	# Minimum packet size for a valid face with blendshapes
	if data.size() < 8:
		return

	# Read face count and basic header
	var stream := StreamPeerBuffer.new()
	stream.data_array = data

	# Face ID
	var _face_id: int = stream.get_32()

	# Camera resolution
	var _cam_w: float = stream.get_float()
	var _cam_h: float = stream.get_float()

	# Skip to rotation (quaternion at offset after eye positions)
	# Right eye 3D (3 floats)
	stream.get_float()
	stream.get_float()
	stream.get_float()
	# Left eye 3D (3 floats)
	stream.get_float()
	stream.get_float()
	stream.get_float()

	# Head rotation as quaternion
	if stream.get_position() + 16 <= data.size():
		var qx: float = stream.get_float()
		var qy: float = stream.get_float()
		var qz: float = stream.get_float()
		var qw: float = stream.get_float()
		var quat := Quaternion(qx, qy, qz, qw)
		head_rotation = quat.get_euler() * (180.0 / PI)

	# Translation (3 floats) — skip
	if stream.get_position() + 12 <= data.size():
		stream.get_float()
		stream.get_float()
		stream.get_float()

	# Confidence
	if stream.get_position() + 4 <= data.size():
		var _confidence: float = stream.get_float()

	# 2D landmarks: 68 points x 2 floats each = 544 bytes
	var landmarks_size := 68 * 2 * 4
	if stream.get_position() + landmarks_size <= data.size():
		stream.seek(stream.get_position() + landmarks_size)

	# 3D landmarks: 68 points x 3 floats = 816 bytes (if present)
	# Check if remaining data is big enough
	var remaining: int = data.size() - stream.get_position()
	if remaining >= 68 * 3 * 4:
		stream.seek(stream.get_position() + 68 * 3 * 4)
		remaining = data.size() - stream.get_position()

	# Blendshape features — typically count (int) then count x float
	if remaining >= 4:
		var feature_count: int = stream.get_32()
		if feature_count > 0 and feature_count < 100:  # sanity
			_raw_weights.clear()
			# OpenSeeFace outputs features in a known order
			var feature_names := _get_feature_names()
			for i in mini(feature_count, feature_names.size()):
				if stream.get_position() + 4 <= data.size():
					var val: float = stream.get_float()
					_raw_weights[feature_names[i]] = clampf(val, 0.0, 1.0)


## OpenSeeFace feature output order (matches their Python tracker)
func _get_feature_names() -> PackedStringArray:
	return PackedStringArray(
		[
			"eyeBlink_L",
			"eyeBlink_R",
			"eyeSquint_L",
			"eyeSquint_R",
			"eyeWide_L",
			"eyeWide_R",
			"browDown_L",
			"browDown_R",
			"browInnerUp",
			"browOuterUp_L",
			"browOuterUp_R",
			"noseSneer_L",
			"noseSneer_R",
			"cheekPuff",
			"cheekSquint_L",
			"cheekSquint_R",
			"jawOpen",
			"jawForward",
			"jawLeft",
			"jawRight",
			"mouthFunnel",
			"mouthPucker",
			"mouthLeft",
			"mouthRight",
			"mouthSmile_L",
			"mouthSmile_R",
			"mouthFrown_L",
			"mouthFrown_R",
			"mouthDimple_L",
			"mouthDimple_R",
			"mouthStretch_L",
			"mouthStretch_R",
			"mouthRollLower",
			"mouthRollUpper",
			"mouthShrugLower",
			"mouthShrugUpper",
			"mouthPress_L",
			"mouthPress_R",
			"mouthLowerDown_L",
			"mouthLowerDown_R",
			"mouthUpperUp_L",
			"mouthUpperUp_R",
			"mouthClose",
			"mouthWide",
			"tongueOut",
		]
	)


## Get viseme weights mapped from ARKit blendshapes.
## Same interface as VisemeDriver.get_viseme_weights().
func get_viseme_weights() -> Dictionary:
	# Reset
	for key in _viseme_weights:
		_viseme_weights[key] = 0.0

	for arkit_name in ARKIT_TO_VISEME:
		if arkit_name in _raw_weights:
			var driver_name: String = ARKIT_TO_VISEME[arkit_name]
			# Max-merge (multiple ARKit shapes can map to same viseme)
			_viseme_weights[driver_name] = maxf(
				_viseme_weights[driver_name], _raw_weights[arkit_name]
			)

	return _viseme_weights


## Get expression weights (blink, emotions) from tracker.
func get_expression_weights() -> Dictionary:
	for key in _expression_weights:
		_expression_weights[key] = 0.0

	for arkit_name in ARKIT_TO_EXPRESSION:
		if arkit_name in _raw_weights:
			var driver_name: String = ARKIT_TO_EXPRESSION[arkit_name]
			_expression_weights[driver_name] = maxf(
				_expression_weights[driver_name], _raw_weights[arkit_name]
			)

	return _expression_weights
