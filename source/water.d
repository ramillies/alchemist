import std.range;
import std.array;
import std.stdio;

import resources;
import tilemap;

import dsfml.graphics;

class Water: Drawable
{
	private
	{
		Tilemap[] animation;
		double fps;
		double cooldown;
		int frame;
	}

	this(int w, int h, double fps = 12.0)
	{
		writefln("width %d, height %d", w, h);
		foreach(k; 0 .. 21)
		{
			animation ~= new Tilemap;
			animation[$-1].load(Images.texture("world water"), Vector2u(288,144), k.repeat(w).array.repeat(h).array);
		}
		frame = 0;
		this.fps = fps;
		cooldown = 1/fps;
	}

	void update(double dt)
	{
		if(dt > cooldown)
		{
			frame = (frame+1) % 21;
			cooldown = 1/fps;
		}
		else
			cooldown -= dt;
	}

	override void draw(RenderTarget target, RenderStates states)
	{
		target.draw(animation[frame], states);
	}
}
