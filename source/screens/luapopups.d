import mainloop;
import messagebox;

import luad.all;

void putPopupsIntoLua(LuaState lua)
{
	lua["messagebox"] = delegate void(string header, string msg) { Mainloop.pushScreen(new MessageBox(header, msg)); }
}
