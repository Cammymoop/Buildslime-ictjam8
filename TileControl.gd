extends Control

export var tileset : TileSet = preload("res://assets/tileset/Main.tres")

func set_tile(index: int):
	var tile_region = tileset.tile_get_region(index)
	var offset = tile_region.position
	$TextureRect.margin_left = -offset.x
	$TextureRect.margin_top = -offset.y
