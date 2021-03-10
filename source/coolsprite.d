import std.conv;

import resources;

import boilerplate;
import dsfml.graphics;

class CoolSprite: Sprite
{
	private
	{
		@Read uint _tilenumber;
		@Read string _texturename;
		@Read bool _relativeOriginAllowed;
		@Read Vector2f _relativeOrigin;
	}
	Vector2u tileSize;

	mixin(GenerateFieldAccessors);

	this() { super(); }

	void setTextureByName(string name)
	{
		_texturename = name;
		this.setTexture(Images.texture(name));
		tileSize = Images.tileSize(name);
	}

	@property void tilenumber(int x)
	{
		auto tilecount = Images.tileCount(_texturename);
		_tilenumber = to!uint((x % tilecount + tilecount) % tilecount); // we need this to work around the fact
		// that modulus of a negative number is negative.

		int tx = _tilenumber % (this.getTexture.getSize.x / tileSize.x);
		int ty = _tilenumber / (this.getTexture.getSize.x / tileSize.x);

		this.textureRect = IntRect(tx*tileSize.x, ty*tileSize.y, tileSize.x, tileSize.y);
	}

	private void updatePosition()
	{
		if(_relativeOriginAllowed)
		{
			auto bounds = this.getLocalBounds();
			this.origin = Vector2f(bounds.left + bounds.width*_relativeOrigin.x, bounds.top + bounds.height*_relativeOrigin.y);
		}
	}

	void setRelativeOrigin(Vector2f u)
	{
		_relativeOriginAllowed = true;
		_relativeOrigin = u;
	}

	void disableRelativeOrigin() { _relativeOriginAllowed = false; }

	override void draw(RenderTarget target, RenderStates states)
	{
		updatePosition;
		super.draw(target, states);
	}
}
