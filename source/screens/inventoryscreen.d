import std.range;
import std.random;
import std.algorithm;
import std.array;
import std.stdio;
import std.format;
import std.math;
import std.conv;
import std.datetime.systime;
import std.json;

import mainloop;
import resources;
import tilemap;
import coolsprite;
import settings;
import player;
import place;
import reacttext;
import gametime;
import messagebox;
import choicebox;

import dsfml.graphics;

class InventoryScreen: Screen
{
	private ReactiveText[] texts, numbers;
	private CoolSprite[] sprites;
	private Player player;
	private GameTime time;
	private int cellsize;
	private RectangleShape[] boxes;
	private const string[] itemList = [
		// Herbs
		"snowbelle", "grasp of winter", "black lotus", "deadly nightshade", "piece of heaven", "desert rose",
		// Monster parts
		"fire spirit part", "water spirit part", "earth spirit part", "air spirit part", "lurking webtrapper part",
		"watcher of eons part", "screeching shellturtle part", "horrid shadesplitter part", "spawn of raknas part",
		"rumbling rocksmasher part", "nimble terrorfly part", "amphibious leecher part",
		// Good potions level 1 to 4
		"fire resistance potion", "earth resistance potion", "water resistance potion", "air resistance potion",
		"satiate potion", "heal potion", "defense potion", "courage potion", "strength potion", "accuracy potion",
		"speed potion", "underwater breathing potion", "battle frenzy potion", "critical hit potion", "penetrating potion",
		"levitation potion", "water walk potion", "tentacles potion", "fire breath potion", "fire shield potion",
		"regeneration potion", "panacea potion", "fortitude potion", "mind resistance potion", "dragon fury potion",
		"wings potion", "unleash kraken potion", "steal attack potion", "stasis potion", "vampiric potion",
		"doppelganger potion", "time loop potion", "angel of death potion",
		// Evil potions ditto
		"lower fire resistance potion", "lower earth resistance potion", "lower water resistance potion", "lower air resistance potion",
		"hunger potion", "poison potion", "vulnerability potion", "fear potion", "weakness potion", "inaccuracy potion",
		"slow potion", "gas breathing potion", "depression potion", "critical miss potion", "lower penetration potion",
		"hold on ground potion", "hold potion", "transform into frog potion", "fire swallow potion", "alchemist fire potion",
		"degeneration potion", "illness potion", "clumsy potion", "love potion", "sleep potion", "atrophy potion", "plague potion",
		"petrify potion", "smoke of hopelessness potion", "power drain potion", "paralysis potion", "mega curse potion",
		"death vortex potion"
	];

	private RenderWindow win;

	this(Player p, GameTime t)
	{
		player = p;
		time = t;
	}

	override void setWindow(RenderWindow w) { win = w; }

	override void init()
	{
		cellsize = 96 * win.size.y / 1080;
		texts = 15.iota.map!((x) => new ReactiveText).array;
		foreach(text; texts)
		{
			text.setFont(Fonts.text);
			text.setCharacterSize(30);
			text.setColor(Color.White);
			text.setRelativeOrigin(Vector2f(.5f, .5f));
			text.boxWidth = .15*win.size.x - 10;
		}

		texts[0].setCharacterSize(20);
		texts[0].positionCallback = () => Vector2f(.925*win.size.x, 0f);
		texts[0].setRelativeOrigin(Vector2f(.5f, 0f));
		texts[0].stringCallback = delegate string()
		{
			auto systime = std.datetime.systime.Clock.currTime;
			return format("%02u:%02u", systime.hour, systime.minute);
		};

		texts[1].positionCallback = () => Vector2f(.925*win.size.x, .95*win.size.y);
		texts[1].stringCallback = () => time.uiString;

		texts[2].setFont(Fonts.heading);
		texts[2].setCharacterSize(35);
		texts[2].setRelativeOrigin(Vector2f(.5f, 1f));
		texts[2].setStyle(Text.Style.Bold);
		texts[2].positionCallback = () => Vector2f(.865*win.size.x, .15*win.size.y);
		texts[2].setString("");
		texts[2].boxWidth = .27*win.size.x - 10;

		texts[3].positionCallback = () => Vector2f(.865*win.size.x, .17*win.size.y);
		texts[3].setRelativeOrigin(Vector2f(.5f, 0f));
		texts[3].setCharacterSize(25);
		texts[3].setString("");
		texts[3].boxWidth = .27*win.size.x - 10;

		with(texts[4])
		{
			setColor(Color(225, 188, 0));
			setRelativeOrigin(Vector2f(.5f, 1f));
			positionCallback = () => Vector2f(.925*win.size.x, .05*win.size.y - 5);
			stringCallback = () => format("%s", player.coins);
		}

		foreach(n; 5 .. 15)
			with(texts[n])
			{
				boxWidth = 0;
				setFont(Fonts.heading);
				setCharacterSize(70*win.size.y/1080);
				setColor(Color.Red);
				if(n < 11) setRelativeOrigin(Vector2f(.5f, 1f));
				else setCharacterSize(6*cellsize/5);
				setString(["Herbs", "Ingredients", "Potions", "Good", "Evil", "Combine", "I", "II", "III", "IV"][n-5]);
			}
		texts[5].positionCallback = () => Vector2f(.425*win.size.x, .7*cellsize);
		texts[6].positionCallback = () => Vector2f(.425*win.size.x, 2.45*cellsize);
		texts[7].positionCallback = () => Vector2f(.425*win.size.x, 4.2*cellsize);
		texts[8].positionCallback = () => Vector2f(.25*.85*win.size.x, 4.4*cellsize);
		texts[8].setCharacterSize(50*win.size.y/1080);
		texts[9].positionCallback = () => Vector2f(.75*.85*win.size.x, 4.4*cellsize);
		texts[9].setCharacterSize(50*win.size.y/1080);
		texts[10].position = Vector2f(.925*win.size.x, .90 * win.size.y);
		foreach(n; 11 .. 15)
			texts[n].position = Vector2f(.425*win.size.x, (5.5 + [0, 2.1, 3.7, 4.8][n - 11])*cellsize);

		int index = 0;
		void makeCellAt(float x, float y)
		{
			auto r = new RectangleShape(Vector2f(cellsize, cellsize));
			r.outlineThickness = -3;
			r.outlineColor = Color.Red;
			r.fillColor = Color(0, 0, 0, 0);
			r.position = Vector2f(x, y);
			boxes ~= r;
			auto t = new ReactiveText;
			t.setFont(Fonts.text);
			t.setCharacterSize(35);
			t.setRelativeOrigin(Vector2f(1f, 1f));
			t.position = Vector2f(x + .95*cellsize, y + .95*cellsize);
			t.setColor(Color.White);
			t.setString("0");
			numbers ~= t;
			auto s = new CoolSprite;
			JSONValue[string] record = ConfigFiles.get("items")[itemList[index]].object;
			string set = record["tileset"].str;
			s.setTextureByName(set);
			s.tilenumber = record["tilenumber"].get!int;
			s.position = Vector2f(x + .05*cellsize, y + .05*cellsize);
			Vector2u size = Images.tileSize(set);
			s.scale = Vector2f(cellsize*.9/size.x, cellsize*.9/size.y);
			sprites ~= s;
			index++;
		}
		// Boxes for herbs
		foreach(n; 0 .. 6)
			makeCellAt(.425*win.size.x + (n-3)*cellsize, .8*cellsize);
		// Boxes for ingredients (monster parts)
		foreach(n; 0 .. 12)
			makeCellAt(.425*win.size.x + (n-6)*cellsize, 2.6*cellsize);
		// Boxes for level 1--3 good potions
		foreach(k; [ 0, 1, 2.1, 3.1, 4.2])
			foreach(n; 0 .. 6)
				makeCellAt(.25*.85*win.size.x + (n-3)*cellsize, (4.5+k)*cellsize);
		// Level 4 good potions
		foreach(n; 0 .. 3)
			makeCellAt(.25*.85*win.size.x + n*cellsize, (4.5 + 5.3)*cellsize);
		// Same for evil potions
		foreach(k; [ 0, 1, 2.1, 3.1, 4.2])
			foreach(n; 0 .. 6)
				makeCellAt(.75*.85*win.size.x + (n-3)*cellsize, (4.5+k)*cellsize);
		foreach(n; 0 .. 3)
			makeCellAt(.75*.85*win.size.x + (n-3)*cellsize, (4.5 + 5.3)*cellsize);
	}

	override void event(Event e)
	{
		if(e.type == e.EventType.Closed)
			Mainloop.quit;
		if(e.type == Event.EventType.KeyPressed)
		{
			if(e.key.code == Keyboard.Key.Escape || e.key.code == Keyboard.Key.I)
				Mainloop.popScreen;
		}
	}

	override void update(double dt)
	{
		auto mousePos = Mouse.getPosition(win);
		texts[2].setString("");
		texts[3].setString("");
		foreach(n; 0 .. itemList.length)
		{
			boxes[n].fillColor = Color(0,0,0,0);
			if(boxes[n].getGlobalBounds.contains(mousePos))
			{
				boxes[n].fillColor = Color(225, 188, 0, 80);
				if(player.items[itemList[n]] > 0)
				{
					auto item = ConfigFiles.get("items")[itemList[n]].object;
					texts[2].setString(item["name"].str);
					texts[3].setString(item["description"].str);
				}
			}
			auto itemcount = player.items[itemList[n]];
			numbers[n].setString(itemcount > 0 ? itemcount.to!string : "");
		}
		texts.each!((t) => t.update);
		numbers.each!((t) => t.update);
	}

	override void updateInactive(double dt)
	{
		texts[0].update;
		texts[1].update;
		texts[4].update;
	}

	override void draw()
	{
		win.clear();
		texts.each!((t) => win.draw(t));
		boxes.each!((t) => win.draw(t));
		foreach(n; 0 .. itemList.length)
			if(player.items[itemList[n]] > 0)
				win.draw(sprites[n]);
		numbers.each!((t) => win.draw(t));
	}

	override void finish()
	{
	}

}
