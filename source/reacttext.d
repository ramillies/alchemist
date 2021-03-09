import std.string;
import std.algorithm;
import std.array;
import std.math;
import std.stdio;

import boilerplate;
import dsfml.graphics;

class ReactiveText: Text
{
	private
	{
		@Write string delegate() _stringCallback;
		@Write Color delegate() _colorCallback;
		@Write Text.Style delegate() _styleCallback;
		@Write uint delegate() _sizeCallback;
		@Write Vector2f delegate() _positionCallback;
		@Read bool _relativeOriginAllowed;
		@Read Vector2f _relativeOrigin;
		@Read @Write double _boxWidth;
	}

	mixin(GenerateFieldAccessors);

	this()
	{
		super();
		_stringCallback = delegate string() { return this.getString(); };
		_colorCallback = delegate Color() { return this.getColor(); };
		_styleCallback = delegate Text.Style () { return this.getStyle(); };
		_sizeCallback = delegate uint () { return this.getCharacterSize(); };
		_positionCallback = delegate Vector2f () { return this.position; };
		_relativeOrigin = Vector2f(0f, 0f);
		_relativeOriginAllowed = false;
		_boxWidth = 0.;
	}

	private void updatePosition()
	{
		if(_relativeOriginAllowed)
		{
			auto bounds = this.getLocalBounds();
			this.origin = Vector2f(bounds.width*_relativeOrigin.x, bounds.height*_relativeOrigin.y);
		}
	}

	private void linebreaks(string txt)
	{
		string doBreaking(string t)
		{
			if(t == "") return "";
			auto words = t.split.array;
			double[] widths;
			foreach(n; 0 .. words.length)
			{
				this.setString(words[0..n+1].join(" ").idup);
				widths ~= this.getLocalBounds.width - (widths.empty ? 0 : widths.sum);
			}

			double optimal = widths.sum / ceil(widths.sum/boxWidth);
			char[] broken;
			double w = 0;
			foreach(k, v; widths)
			{
				if(w + v > boxWidth)
				{
					broken ~= (w == 0 ? "" : "\n") ~ words[k] ~ (w == 0 ? "\n" : "");
					w = (w == 0) ? 0 : v;
				}
				else if(optimal <= (w+v))
				{
					broken ~= words[k] ~ "\n";
					w = 0;
				}
				else
				{
					broken ~= words[k] ~ " ";
					w += v;
				}
			}
			return broken.idup;
		}
		this.setString(txt.split("\n").map!((a) => doBreaking(a)).join("\n").idup);
	}

	void setRelativeOrigin(Vector2f u)
	{
		_relativeOriginAllowed = true;
		_relativeOrigin = u;
	}

	void disableRelativeOrigin() { _relativeOriginAllowed = false; }

	void update()
	{
		this.setColor(_colorCallback());
		this.setStyle(_styleCallback());
		this.setCharacterSize(_sizeCallback());
		this.position = _positionCallback();
		if(boxWidth != 0.)
			linebreaks(_stringCallback());
		else
			this.setString(_stringCallback());

		updatePosition();
	}

}
