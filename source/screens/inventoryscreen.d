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
import potiontable;
import endgamescreen;

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
	private int[] selected;
	private RectangleShape combineButton;
	private PotionTable potionTable;

	private RenderWindow win;

	this(Player p, GameTime t, PotionTable pot)
	{
		player = p;
		time = t;
		selected = [ -1, -1 ];
		potionTable = pot;
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
		texts[10].position = Vector2f(.9*win.size.x, .90 * win.size.y);
		foreach(n; 11 .. 15)
			texts[n].position = Vector2f(.425*win.size.x, (5.5 + [0, 2.1, 3.7, 4.8][n - 11])*cellsize);

		combineButton = new RectangleShape(Vector2f(texts[10].getLocalBounds.width + 20, texts[10].getLocalBounds.height + 20));
		combineButton.fillColor = Color.Black;
		combineButton.outlineThickness = 10;
		combineButton.outlineColor = Color(120, 120, 120);

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
			if(e.key.code == Keyboard.Key.N)
			{
				auto knowledge = chain(
					potionTable.largeInfo.filter!`a.known`.map!`a.description`,
					potionTable.medInfo.filter!`a.known && !a.obsolete`.map!`a.description`
				);
				Mainloop.pushScreen(new MessageBox(
					"Your notes",
					knowledge.empty ? "You haven't written down any notes yet." :
					format("You know that a %s CANNOT be made:\n\n%-(%s;\n%).", ConfigFiles.get("potions")["youth potion"]["name"].str, knowledge),
					.7, .7
				));
			}
		}
		if(e.type == Event.EventType.MouseButtonPressed)
		{
			foreach(k, v; boxes)
				if(v.getGlobalBounds.contains(Mouse.getPosition(win)))
				{
					selectBox(k);
					break;
				}
			if(selected.all!`a!=-1` && texts[10].getGlobalBounds().contains(Mouse.getPosition(win)))
			{
				foreach(n; selected)
					player.items[itemList[n]]--;
				auto mixResult = potionTable.mixResult(itemList[selected[0]], itemList[selected[1]]);
				if(mixResult.result == "")
				{
					Mainloop.pushScreen(new MessageBox("Poof!",
						format("You tried to prepare a mixture of %s and %s, but you got only copious amounts of thick black stinking smoke. The ingredients are wasted.\n\n%s",
							ConfigFiles.get("items")[itemList[selected[0]]]["name"].str,
							ConfigFiles.get("items")[itemList[selected[1]]]["name"].str,
							mixResult.infoType == "medium"
								? format("You learnt that %s, and wrote that down into your notebook.", potionTable.medInfo[mixResult.infoIndex].description)
								: mixResult.infoType == "small"
									? format("You learnt that %s, and wrote that down into your notebook.", potionTable.smallInfo[mixResult.infoIndex].description)
									: ""
							)
					));
					unselectAll();
				}
				else
				{
					player.items[mixResult.result]++;
					if(mixResult.result == "youth potion")
						Mainloop.pushScreen(new EndGameScreen(player, potionTable, "Victory!"));
					if(mixResult.infoType == "small")
						Mainloop.pushScreen(new MessageBox("A new find!",
							format("You now know that %s, and wrote that down into your notebook.", potionTable.smallInfo[mixResult.infoIndex].description)
						));
				}
				if(selected.any!((n) => n == -1 || player.items[itemList[n]] < 1))
					unselectAll();
			}
		}
	}

	override void update(double dt)
	{
		auto mousePos = Mouse.getPosition(win);
		bool combineSelected = selected.all!`a!=-1` && texts[10].getGlobalBounds().contains(Mouse.getPosition(win));
		texts[10].setColor(selected.all!`a!=-1` ? Color.Red : Color(120, 120, 120));
		combineButton.position = Vector2f(texts[10].getGlobalBounds.left - 10, texts[10].getGlobalBounds.top - 10);
		combineButton.fillColor = combineSelected ? Color(225, 188, 0, 80) : Color(0, 0, 0, 0);
		combineButton.outlineColor = selected.all!`a!=-1` ? Color.Red : Color(120, 120, 120);
		texts[2].setString("");
		texts[3].setString("");
		foreach(n; 0 .. itemList.length)
		{
			boxes[n].fillColor = Color(0,0,0,0);
			boxes[n].outlineColor = selected.canFind(cast(int)n) ? Color.Green : Color.Red;
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
			if(selected.count!`a != -1` == 1)
			{
				auto sel = selected[selected.countUntil!`a != -1`];
				if(n < 18)
				{
					foreach(info; potionTable.smallInfo.filter!`a.known`)
						if(info.inputMatches(itemList[sel], itemList[n]))
							boxes[n].fillColor = info.output == "" ? Color(200, 0, 0, 80) : Color(0, 200, 0, 80);
				}
				else if(n < 48 || (n > 50 && n < 81))
				{
					if(potionTable.tableLookup(itemList[sel], itemList[n]) != "")
						boxes[n].fillColor = Color(0, 200, 0, 80);
					else
						boxes[n].fillColor = Color(200, 0, 0, 80);
				}
				else
				{
					foreach(info; potionTable.medInfo.filter!`a.known`)
						if(info.inputMatches(itemList[sel], itemList[n]))
							boxes[n].fillColor = Color(200, 0, 0, 80);
				}
			}
			if(selected.count!`a != -1` == 2)
			{
				if(selected[0] < 18)
				{
					foreach(info; potionTable.smallInfo.filter!`a.known`)
						if(info.inputMatches(itemList[selected[0]], itemList[selected[1]]) && info.output == itemList[n])
							boxes[n].outlineColor = Color(255, 255, 0);
				}
				else
				{
					foreach(key, val; potionTable.table)
						if(((itemList[selected[0]] == key[0] && itemList[selected[1]] == key[1])
						|| (itemList[selected[1]] == key[0] && itemList[selected[0]] == key[1]))
						&& itemList[n] == val)
							boxes[n].outlineColor = Color(255, 255, 0);
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
		win.draw(combineButton);
	}

	override void finish() { }

	private void selectBox(size_t index)
	{
		if(player.items[itemList[index]] < 1) return;
		int n = cast(int) index;
		if(selected.canFind(n))
		{
			foreach(ref k; selected)
				if(k == n)
					k = -1;
		}
		else
			foreach(ref k; selected)
				if(k == -1)
				{
					k = n;
					break;
				}

	}

	private void unselectAll()
	{
		foreach(ref k; selected)
			k = -1;
	}
}
