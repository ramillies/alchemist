import std.algorithm;

import world;
import resources;
import util;

import luad.all;
import dsfml.graphics;

class Player: Drawable
{
	size_t x, y;
	int[string] items;
	int coins;
	private Sprite sprite;

	this(size_t x, size_t y)
	{
		this.x = x;
		this.y = y;
		coins = 0;
		sprite = new Sprite;
		sprite.setTexture(Images.texture("people"));
		sprite.setTileNumber(5, Vector2u(108, 108));
		sprite.origin = Vector2f(sprite.getLocalBounds.width/2, sprite.getLocalBounds.height/2);

		foreach(herb; ConfigFiles.get("herbs").keys)
			items[herb] = 0;
		foreach(ingredient; ConfigFiles.get("ingredients").keys)
			items[ingredient] = 0;
		foreach(potion; ConfigFiles.get("potions").keys)
			items[potion] = 0;
	}

	void luaPutInto(LuaTable obj)
	{
		obj["ptr"] = ptr2string(cast(void *) this);
		obj["getX"] = delegate size_t(LuaTable t) { return string2ptr!Player(t.get!string("ptr")).x; };
		obj["getY"] = delegate size_t(LuaTable t) { return string2ptr!Player(t.get!string("ptr")).y; };
		obj["setPosition"] = delegate void(LuaTable t, size_t x, size_t y)
		{
			auto me = string2ptr!Player(t.get!string("ptr"));
			me.x = x; me.y = y;
		};
		obj["giveItems"] = delegate void(LuaTable t, int[string] given)
		{
			auto me = string2ptr!Player(t.get!string("ptr"));
			foreach(key, val; given)
			{
				if(key in me.items)
					me.items[key] = max(0, me.items[key]+val);
				else
					me.items[key] = max(0, val);

			}
		};
		obj["getItems"] = delegate int[string](LuaTable t) { return string2ptr!Player(t.get!string("ptr")).items; };
		obj["setItems"] = delegate void(LuaTable t, int[string] x) { string2ptr!Player(t.get!string("ptr")).items = x; };
		obj["getCoins"] = delegate int(LuaTable t) { return string2ptr!Player(t.get!string("ptr")).coins; };
		obj["setCoins"] = delegate void(LuaTable t, int x) { string2ptr!Player(t.get!string("ptr")).coins = x; };
		obj["giveCoins"] = delegate void(LuaTable t, int x) { auto me = string2ptr!Player(t.get!string("ptr")); me.coins = max(0, me.coins + x); };
	}

	override void draw(RenderTarget target, RenderStates states)
	{
		sprite.position = Vector2f(3*World.TILESIZE*x + 3*World.TILESIZE/2, 3*y*World.TILESIZE + 3*World.TILESIZE/2);
		target.draw(sprite, states);
	}
}
