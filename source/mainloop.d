import std.range;
import std.stdio;
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
		writefln("Now having %s screens", screens);
	}

	static void popScreen()
	{
		writefln("Now having %s screens", screens);
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
			foreach(s; screens)
				s.update(clock.getElapsedTime.total!"hnsecs" * 1e-7);
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
