import std.range;
import dsfml.graphics;

interface Screen
{
	void init();
	void setWindow(RenderWindow win);
	void event(Event e);
	void update(double dt);
	void draw();
	void finish();
}

class Mainloop
{
	static Screen[] screens;
	static bool shouldQuit = false;
	static Clock clock = null;
	static RenderWindow win = null;

	static void quit()
	{
		shouldQuit = true;
	}

	static void changeScreen(Screen s)
	{
		if(!clock) clock = new Clock;
		while(!screens.empty)
			popScreen();
		pushScreen(s);
	}

	static void pushScreen(Screen s)
	{
		s.setWindow(win);
		s.init;
		clock.restart;
		screens ~= s;
	}

	static void popScreen()
	{
		if(!screens.empty)
		{
			screens[$-1].finish;
			screens = screens[0 .. $-1];
		}
	}

	static void mainloop()
	{
		if(screens.empty || !win)
			return;

		while(!shouldQuit)
		{
			Event e;
			while(win.pollEvent(e))
				screens[$-1].event(e);
			screens[$-1].update(clock.getElapsedTime.total!"hnsecs" * 1e-7);
			clock.restart;

			win.clear;
			foreach(s; screens)
				s.draw;
			win.display;
		}

		while(!screens.empty)
			popScreen();
	}
}
