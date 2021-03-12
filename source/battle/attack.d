import stats;
import effect;

import boilerplate;

class Attack
{
	private
	{
		@Read AttackType _type;
		@Read int _strength;
		@Read double _hitChance;
		@Read Effect[] _effectsToAdd;
		@Read int[][] delegate(int) _targets;
	}

	mixin(GenerateAll);
}
