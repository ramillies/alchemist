import std.algorithm, std.array, std.range;
import std.typecons;
import coolsprite;
import reacttext;
import stats;
import battletime;

import dsfml.graphics;

class Unit: TimeRegistrable, Transformable, Drawable
{
	string name, description;
	private Stats baseStats, checkpointStats, stats;
	private CoolSprite sprite;
	private bool battle;
	private BattleTime time;
	private Unit[] friends, enemies;
	bool dead, fled;
	int squadPosition;

	this(string n, string d, Stats s)
	{
		name = n;
		description = d;
		baseStats = s;
		checkpointStats = s;
		stats = s;
		sprite = new CoolSprite;
		dead = false;
		fled = false;
		squadPosition = -1;
	}

	void setTextureByName(string name) { sprite.setTextureByName(name); }
	void setRelativeOrigin(Vector2f o) { sprite.setRelativeOrigin(o); }
	@property void tilenumber(int x) { sprite.tilenumber = x; }

	void startBattle(BattleTime t, Unit[] f, Unit[] e)
	{
		battle = true;
		friends = f;
		enemies = e;
		saveCheckpoint;
	}

	void endBattle()
	{
		battle = false;
		dead = false; fled = false;
		restoreCheckpoint;
	}

	void saveCheckpoint() { checkpointStats = baseStats; }
	void restoreCheckpoint() { baseStats = checkpointStats; }

	override Tuple!(double, "cooldown", double, "speedFactor") takeTurn()
	{
		return tuple!("cooldown", "speedFactor")(1., 1.);
	}

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
