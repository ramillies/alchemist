import std.array;
import std.algorithm;
import std.stdio;
import std.json;
import std.range;
import std.conv;

import mainloop;
import resources;
import reacttext;
import coolsprite;

import luad.all;
import dsfml.graphics;

struct Choice
{
	CoolSprite sprite;
	string text;
	void delegate() callback;
	ReactiveText textRendering;
	bool disabled;

	static Choice fromLuaTable(LuaTable obj)
	{
		CoolSprite sprite;
		string text = "";
		void delegate() callback = delegate void() { };
		ReactiveText t = new ReactiveText;
		bool disabled = false;
		
		if(!obj["text"].isNil) text = obj.get!string("text");
		if(!obj["callback"].isNil) callback = obj.get!(void delegate())("callback");
		if(!obj["disabled"].isNil) disabled = obj.get!bool("disabled");
		if(!obj["tileset"].isNil && Images.exists(obj.get!string("tileset")))
		{
			sprite = new CoolSprite;
			sprite.setTextureByName(obj.get!string("tileset"));
			if(!obj["tilenumber"].isNil)
				sprite.tilenumber = obj.get!int("tilenumber");
		}

		return Choice(sprite, text, callback, t, disabled);
	}
}

class ChoiceBox: Screen
{
	private ReactiveText[] texts;
	private RenderWindow win;
	private string heading, msg;
	private Choice[] choices;
	const int ROWHEIGHT = 50;
	private View camera;
	private RectangleShape cursor;

	this(string h, string m, Choice[] c)
	{
		heading = h;
		msg = m;
		choices = c;
	}

	override void init()
	{
		writefln("Initing choicebox");
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
			setRelativeOrigin(Vector2f(.5f, 0f));
			positionCallback = () => Vector2f(.5*win.size.x, .35*win.size.y);
			stringCallback = () => msg;
		}
		with(texts[2])
		{
			setFont(Fonts.italic);
			setCharacterSize(25);
			setRelativeOrigin(Vector2f(.5f, 1f));
			positionCallback = () => Vector2f(.5*win.size.x, .75*win.size.y - 5);
			stringCallback = () => "(Scroll and click with mouse or scroll with PgUp/PgDn and hit the indicated key combination.)";
		}

		foreach(n, choice; choices)
		{
			writefln("\tChoice %s: %s", n, choice);
			with(choice.textRendering)
			{
				setFont(Fonts.text);
				sizeCallback = () => 35;
				boxWidth = win.size.x/2 - ROWHEIGHT;
				if(choice.disabled)
					setColor(Color(100, 100, 100));
				else
					setColor(Color.White);
				setRelativeOrigin(Vector2f(0f, .5f));
				position = Vector2f(ROWHEIGHT+20, n*ROWHEIGHT + ROWHEIGHT/2);
				setString(choice.text);
			}
			if(choice.sprite !is null)
			{
				with(choice.sprite)
				{
					setRelativeOrigin(Vector2f(.5f, .5f));
					position = Vector2f(ROWHEIGHT/2, ROWHEIGHT/2 + n*ROWHEIGHT);
					auto bound = getLocalBounds();
					scale = Vector2f(ROWHEIGHT/bound.height, ROWHEIGHT/bound.height);
					if(choice.disabled)
						color = Color(100, 100, 100);
				}
			}
		}

		camera = new View(FloatRect(0, 0, .45 * win.size.x, .26 * win.size.y));
		camera.viewport = FloatRect(.275f, .46f, .45f, .26f);

		cursor = new RectangleShape(Vector2f(.45*win.size.x, ROWHEIGHT));
		cursor.fillColor = Color(225, 188, 0, 80);
	}

	override void setWindow(RenderWindow w) { win = w; }

	override void event(Event e)
	{
		if(e.type == Event.EventType.MouseWheelMoved)
			camera.center = Vector2f(camera.center.x, clamp(camera.center.y - ROWHEIGHT*e.mouseWheel.delta, camera.size.y/2, max(choices.length*ROWHEIGHT - camera.size.y/2, camera.size.y/2)));
		if(e.type == Event.EventType.MouseButtonPressed)
		{
			if(e.mouseButton.button == Mouse.Button.Left && mouseRow() != -1 && !choices[mouseRow()].disabled)
			{
				Mainloop.popScreen;
				choices[mouseRow()].callback();
			}
		}
	}

	override void update(double dt)
	{
		texts.each!((t) => t.update);
		choices.each!((c) => c.textRendering.update);
	}

	override void draw()
	{
		RectangleShape r = new RectangleShape(Vector2f(.5 * win.size.x, .5*win.size.y));
		r.fillColor = Color.Black;
		r.outlineThickness = win.size.x/100;
		r.outlineColor = Color.Red;
		r.position = Vector2f(.25*win.size.x, .25*win.size.y);

		win.draw(r);
		texts.each!((t) => win.draw(t));

		if(camera.size.y < choices.length*ROWHEIGHT)
		{
			RectangleShape bar = new RectangleShape(Vector2f(10f, camera.size.y ^^ 2 /ROWHEIGHT/choices.length));
			bar.fillColor = Color.Red;
			bar.position = Vector2f(.7375*win.size.x - 5, .46*win.size.y + camera.size.y * (camera.center.y - camera.size.y/2)/choices.length/ROWHEIGHT);
			win.draw(bar);
		}

		win.view = camera;
		foreach(c; choices)
		{
			if(c.sprite !is null)
				win.draw(c.sprite);
			win.draw(c.textRendering);
		}
		if(mouseRow() != -1 && !choices[mouseRow()].disabled)
		{
			cursor.position = Vector2f(0f, ROWHEIGHT*mouseRow());
			win.draw(cursor);
		}

	}

	private int mouseRow()
	{
		auto cw = camera.viewport;
		if(FloatRect(cw.left*win.size.x, cw.top*win.size.y, cw.width*win.size.x, cw.height*win.size.y).contains(Mouse.getPosition(win)))
		{
			auto pt = win.mapPixelToCoords(Mouse.getPosition(win), camera);
			return clamp(to!int(pt.y/ROWHEIGHT), 0, choices.length-1);
		}
		else
			return -1;
	}

	override void finish()
	{
	}
}

