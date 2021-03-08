import std.array;
import std.stdio;
import std.json;

import mainloop;
import resources;
import gamescreen;
import world;

import dsfml.graphics;

class LoadingScreen: Screen
{
	private int stage;
	private Text text;
	private RenderWindow win;

	override void init()
	{
		stage = 0;
		Fonts.load;

		text = new Text;
		text.setFont(Fonts.gentium);
		text.setCharacterSize(80);
		text.setColor(Color.Red);
	}

	override void setWindow(RenderWindow w)
	{
		win = w;
	}

	private void loadingText(string str)
	{
		text.setString(str);
		auto bounds = text.getGlobalBounds;
		text.origin = Vector2f(bounds.width/2, bounds.height/2);
	}

	override void event(Event e)
	{
	}

	override void update(double dt)
	{
		if(stage == 1)
		{
			Images.load;
			// Things.load;
		}
		if(stage == 2)
		{
			World w = new World(40, 40, .4);
			w.makeTerrain;
			w.addTerrainFeatures;

			Mainloop.changeScreen(new GameScreen(w));
		}
	}

	override void draw()
	{
		if(stage == 1)
		{
			loadingText("Generating map...");
			stage = 2;
		}
		if(stage == 0)
		{
			loadingText("Loading textures...");
			stage = 1;
		}

		text.position = Vector2f(win.size.x/2, win.size.y/2);
		win.draw(text);
	}

	override void finish()
	{
	}
}
