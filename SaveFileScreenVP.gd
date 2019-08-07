extends Viewport

func show_screenshot(name : String):
	var img = Image.new()
	if img.load("user://screenshots/" + name) == OK:
		var texture = ImageTexture.new()
		texture.create_from_image(img)
		$Sprite.texture = texture
		$Sprite.visible = true
		
		$LogoSprite.visible = false

func reset():
	$Sprite.visible = false
	$LogoSprite.visible = true