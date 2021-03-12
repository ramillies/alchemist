import coolsprite;
import reacttext;
import stats;

import dsfml.graphics;

class Unit: Transformable, Drawable
{
	private Stats baseStats, checkpointStats, stats;
	private CoolSprite sprite;

	this(Stats s)
	{
		baseStats = s;
		checkpointStats = s;
		stats = s;
		sprite = new CoolSprite;
	}

	void setTextureByName(string name) { sprite.setTextureByName(name); }
	void setRelativeOrigin(Vector2f o) { sprite.setRelativeOrigin(o); }

	@property void tilenumber(int x) { sprite.tilenumber = x; }

	mixin NormalTransformable;

	override void draw(RenderTarget target, RenderStates states)
	{
		sprite.position = position;
		sprite.origin = origin;
		sprite.rotation = rotation;
		sprite.scale = scale;
		target.draw(sprite, states);
	}

}
