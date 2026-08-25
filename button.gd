extends Button

var done = false

func _on_pressed() -> void:
	if not done:
		done = true
		var node: RpgdlNode = get_tree().get_first_node_in_group(RpgdlNode.RPGDL_NODE_GROUP)
		node.start_script()
		
	
