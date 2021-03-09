import resources;

import boilerplate;
import dsfml.graphics;

class CoolSprite: Sprite
{
	private @Read uint _tilenumber;
	private @Read string _texturename;
	Vector2u tileSize;

	mixin(GenerateFieldAccessors);

	this() { super(); }

	void setTextureByName(string name)
	{
		_texturename = name;
		this.setTexture(Images.texture(name));
		tileSize = Images.tileSize(name);
	}

	@property void tilenumber(uint x)
	{
		_tilenumber = x % Images.tileCount(_texturename);
		int tx = _tilenumber % (this.getTexture.getSize.x / tileSize.x);
		int ty = _tilenumber / (this.getTexture.getSize.x / tileSize.x);

		this.textureRect = IntRect(tx*tileSize.x, ty*tileSize.y, tileSize.x, tileSize.y);
	}
}
