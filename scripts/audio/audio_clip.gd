class_name AudioClip
extends Resource

## Resource đại diện cho một audio clip
## Audio engineer có thể tạo AudioClip resource và thêm vào AudioDatabase

@export var clip_id: String = ""
@export var stream: AudioStream = null
@export var volume_db: float = 0.0
@export var randomize_pitch: bool = false
@export_range(0.1, 2.0) var pitch_min: float = 0.9
@export_range(0.1, 2.0) var pitch_max: float = 1.1

## Mô tả để audio engineer ghi chú
@export_multiline var description: String = ""
