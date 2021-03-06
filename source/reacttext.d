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
		@Read bool _drawOutline;
		@Read int _outlineThickness;
		@Read Color _outlineColor;
	}

	mixin(GenerateFieldAccessors);

	this()
	{
		super();
		_relativeOrigin = Vector2f(0f, 0f);
		_relativeOriginAllowed = false;
		_boxWidth = 0.;
		_drawOutline = false;
		_outlineColor = Color(0,0,0,0);
		_outlineThickness = 0;
	}

	private void updatePosition()
	{
		if(_relativeOriginAllowed)
		{
			auto bounds = this.getLocalBounds();
			this.origin = Vector2f(bounds.left, bounds.top) + Vector2f(bounds.width*_relativeOrigin.x, bounds.height*_relativeOrigin.y);
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
					broken ~= (w == 0 ? "" : "\n") ~ words[k] ~ (w == 0 ? "\n" : " ");
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
		this.setString(txt.split("\n").map!((a) => doBreaking(a).strip("\n")).join("\n").idup);
	}

	void setRelativeOrigin(Vector2f u)
	{
		_relativeOriginAllowed = true;
		_relativeOrigin = u;
	}

	void disableRelativeOrigin() { _relativeOriginAllowed = false; }

	void setOutline(int frac, Color color)
	{
		_drawOutline = true;
		_outlineThickness = frac;
		_outlineColor = color;
	}

	void disableOutline() { _drawOutline = false; }

	void update()
	{
		if(_colorCallback !is null) this.setColor(_colorCallback());
		if(_styleCallback !is null) this.setStyle(_styleCallback());
		if(_sizeCallback !is null) this.setCharacterSize(_sizeCallback());
		if(_positionCallback !is null) this.position = _positionCallback();
		string t = (_stringCallback is null) ? this.getString() : _stringCallback();
		if(boxWidth != 0.)
			linebreaks(t);
		else
			this.setString(t);

		updatePosition();
	}

	override void draw(RenderTarget target, RenderStates states)
	{
		if(_drawOutline && Shader.isAvailable)
		{
			auto savePos = this.position;
			auto saveColor = this.getColor();
			this.setColor(_outlineColor);
			foreach(k; -_outlineThickness .. _outlineThickness)
				foreach(l; -_outlineThickness .. _outlineThickness)
					if((k^^2 + l^^2) <= _outlineThickness ^^ 2)
					{
						this.position = Vector2f(savePos.x + k, savePos.y + l);
						super.draw(target, states);
					}
			this.setColor(saveColor);
			this.position = savePos;
		}
		super.draw(target, states);
	}

}
