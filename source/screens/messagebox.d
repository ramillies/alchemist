import std.array;
import std.algorithm;
import std.stdio;
import std.json;
import std.range;

import mainloop;
import resources;
import reacttext;

import dsfml.graphics;

class MessageBox: Screen
{
	private ReactiveText[] texts;
	private RenderWindow win;
	private string heading, msg;

	this(string h, string m)
	{
		heading = h;
		msg = m;
	}

	override void init()
	{
		texts = 3.iota.map!((x) => new ReactiveText).array;
		foreach(txt; texts)
		{
			txt.setFont(Fonts.text);
			txt.setColor(Color.White);
			txt.boxWidth = win.size.x/2;
		}
		with(texts[0])
		{
			setFont(Fonts.heading);
			setCharacterSize(80);
			setColor(Color.Red);
			setStyle(Text.Style.Bold);
			setRelativeOrigin(Vector2f(.5f, 0f));
			positionCallback = () => Vector2f(.5*win.size.x, .25*win.size.y + 5);
			stringCallback = () => heading;
		}
		with(texts[1])
		{
			setCharacterSize(40);
			setRelativeOrigin(Vector2f(.5f, .5f));
			positionCallback = () => Vector2f(.5*win.size.x, .5*win.size.y);
			stringCallback = () => msg;
		}
		with(texts[2])
		{
			setFont(Fonts.italic);
			setCharacterSize(25);
			setRelativeOrigin(Vector2f(.5f, 1f));
			positionCallback = () => Vector2f(.5*win.size.x, .75*win.size.y - 5);
			stringCallback = () => "(Press any key or mouse button to get rid of this popup.)";
		}
	}

	override void setWindow(RenderWindow w) { win = w; }

	override void event(Event e)
	{
		if(e.type == Event.EventType.KeyPressed || e.type == Event.EventType.MouseButtonPressed)
			Mainloop.popScreen;
	}

	override void update(double dt) { texts.each!((t) => t.update); }
	override void updateInactive(double dt) { }

	override void draw()
	{
		RectangleShape r = new RectangleShape(Vector2f(.5 * win.size.x, .5*win.size.y));
		r.fillColor = Color.Black;
		r.outlineThickness = win.size.x/100;
		r.outlineColor = Color.Red;
		r.position = Vector2f(.25*win.size.x, .25*win.size.y);

		win.draw(r);
		texts.each!((t) => win.draw(t));
	}

	override void finish()
	{
	}
}

