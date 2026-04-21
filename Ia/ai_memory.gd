# ai_memory.gd
extends Node

# 📊 dados de aprendizado
var tower_usage: Dictionary = {}
var tower_performance: Dictionary = {}
var slot_success: Dictionary = {}
var combo_success: Dictionary = {}

# -------------------------------
# 📌 REGISTRAR CONSTRUÇÃO
# -------------------------------
func register_build(tower_name: String, slot_position: Vector3):

	tower_usage[tower_name] = tower_usage.get(tower_name, 0) + 1

	var slot_id = _get_slot_id(slot_position)
	slot_success[slot_id] = slot_success.get(slot_id, 0) + 1

# -------------------------------
# 📌 REGISTRAR DANO
# -------------------------------
func register_damage(tower_name: String, damage: float):

	tower_performance[tower_name] = tower_performance.get(tower_name, 0.0) + damage

# -------------------------------
# 📌 REGISTRAR COMBO
# -------------------------------
func register_combo(tower_name: String, nearby_builds: Array):

	for b in nearby_builds:
		if not b.has_method("get_build_name"):
			continue

		var other_name = b.get_build_name()
		var key = tower_name + "+" + other_name

		combo_success[key] = combo_success.get(key, 0) + 1

# -------------------------------
# 📌 GERAR ID DO SLOT
# -------------------------------
func _get_slot_id(pos: Vector3) -> String:
	return str(round(pos.x)) + "_" + str(round(pos.z))

# -------------------------------
# 💾 SALVAR
# -------------------------------
func save_data():

	var file = FileAccess.open("user://ai_data.save", FileAccess.WRITE)

	file.store_var({
		"usage": tower_usage,
		"performance": tower_performance,
		"slots": slot_success,
		"combo": combo_success
	})

# -------------------------------
# 📂 CARREGAR
# -------------------------------
func load_data():

	if not FileAccess.file_exists("user://ai_data.save"):
		return

	var file = FileAccess.open("user://ai_data.save", FileAccess.READ)
	var data = file.get_var()

	tower_usage = data.get("usage", {})
	tower_performance = data.get("performance", {})
	slot_success = data.get("slots", {})
	combo_success = data.get("combo", {})

# -------------------------------
# 🔄 RESET (debug)
# -------------------------------
func reset():
	tower_usage.clear()
	tower_performance.clear()
	slot_success.clear()
	combo_success.clear()
