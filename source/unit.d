import std.algorithm, std.array, std.range;
import std.typecons;
import std.format;
import std.json;
import std.conv;

import coolsprite;
import reacttext;
import stats;
import battletime;
import battlescreen;
import attack;
import resources;

import dsfml.graphics;
import boilerplate;

class Unit: TimeRegistrable, Transformable, Drawable
{
	string name, description;
	@(ToString.Exclude) private Stats baseStats, checkpointStats;
	private Stats stats;
	private CoolSprite sprite;
	private bool battle;
	@(ToString.Exclude) private BattleTime time;
	@(ToString.Exclude) private BattleScreen screen;
	@(ToString.Exclude) private Unit[] friends, enemies;
	private ReactiveText hpText, speedText;
	bool dead, fled;
	int squadPosition;

	mixin(GenerateToString);

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

		hpText = new ReactiveText;
		with(hpText)
		{
			setCharacterSize(25);
			setFont(Fonts.text);
			setColor(Color.White);
			setRelativeOrigin(Vector2f(.5f, 0f));
			stringCallback = () => format("%s / %s", stats.hp, stats.maxhp);
		}		
		speedText = new ReactiveText;
		with(speedText)
		{
			setCharacterSize(25);
			setFont(Fonts.text);
			setColor(Color.White);
			setRelativeOrigin(Vector2f(.5f, 1f));
			stringCallback = () => (cooldowns.keys.length > 1)
				? format("%s = %(%s+%)", cooldowns.values.sum.to!int, cooldowns.values.map!`a.to!int`.array)
				: format("%s", cooldowns.values.sum.to!int);
		}		
	}

	void setTextureByName(string name) { sprite.setTextureByName(name); }
	void setRelativeOrigin(Vector2f o) { sprite.setRelativeOrigin(o); }
	@property void tilenumber(int x) { sprite.tilenumber = x; }

	override @property double speed() { return stats.speed; }

	void applyAttack(Attack attack)
	{
		auto hp = stats.hp;
		auto result = stats.takeHit(attack);
		auto damageSuffered = hp - stats.hp;
		baseStats.hp = baseStats.hp - damageSuffered;
		baseStats.effects = stats.effects;
		if(stats.hp <= 0)
		{
			dead = true;
			time.unregister(this);
		}
	}

	void update()
	{
		stats = baseStats.applyEffects();
	}

	void startBattle(BattleScreen s, BattleTime t, Unit[] f, Unit[] e)
	{
		time = t;
		screen = s;
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

	static Unit byName(string name)
	{
		JSONValue x = ConfigFiles.get("units")[name].object;
		auto ret = new Unit(x["name"].str, x["description"].str,
			Stats.fromJSON(x));
		if("tileset" in x)
			ret.setTextureByName(x["tileset"].str);
		if("tilenumber" in x)
			ret.tilenumber = x["tilenumber"].get!int;
		return ret;
	}
	

	override Tuple!(double, "cooldown", double, "speedFactor") takeTurn()
	{
		foreach(enemy; enemies)
			if(enemy !is null)
				enemy.applyAttack(this.stats.attack);
		return tuple!("cooldown", "speedFactor")(2., 1.);
	}

	mixin NormalTransformable;

	override void draw(RenderTarget target, RenderStates states)
	{
		hpText.update;
		speedText.update;
		sprite.position = position;
		sprite.rotation = rotation - (dead ? 90 : 0);
		sprite.scale = scale;

		auto bounds = sprite.getGlobalBounds();
		hpText.position = Vector2f(bounds.left + bounds.width/2, bounds.top + bounds.height + 5);
		speedText.position = Vector2f(bounds.left + bounds.width/2, bounds.top - 5);

		target.draw(sprite, states);
		if(!dead)
		{
			target.draw(hpText, states);
			target.draw(speedText, states);
		}
	}

}
