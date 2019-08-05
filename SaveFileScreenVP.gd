extends Viewport

func show_screenshot(name : String):
	var img = Image.new()
	if not img.load("user://screenshots/" + name + ".png"):
		var texture = ImageTexture.new()
		texture.create_from_image(img)
		$Sprite.texture = texture