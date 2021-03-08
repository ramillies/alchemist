import world;
import resources;
import util;

import dsfml.graphics;

class Player: Drawable
{
	size_t x, y;
	private Sprite sprite;

	this(size_t x, size_t y)
	{
		this.x = x;
		this.y = y;
		sprite = new Sprite;
		sprite.setTexture(Images.texture("people"));
		sprite.setTileNumber(5, Vector2u(108, 108));
		sprite.origin = Vector2f(sprite.getLocalBounds.width/2, sprite.getLocalBounds.height/2);
	}

	override void draw(RenderTarget target, RenderStates states)
	{
		sprite.position = Vector2f(3*World.TILESIZE*x + 3*World.TILESIZE/2, 3*y*World.TILESIZE + 3*World.TILESIZE/2);
		target.draw(sprite, states);
	}
}
