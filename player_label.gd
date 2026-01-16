extends Control



func set_info(name: String, color: Color = Color.WHITE):
	var image = Image.create(32, 32, false, Image.FORMAT_RGBA8)
	image.fill_rect(Rect2i(0, 0, 32, 32), color) # Fill the image with the color
	var texture = ImageTexture.create_from_image(image) # Create a texture from the image
	$TextureRect.texture = texture

	$Label.text = name
