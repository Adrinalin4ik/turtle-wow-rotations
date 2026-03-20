# How to use
1. Download the latest version from github
2. Unpack it to \Interface\AddOns folder inside of wow client directory
3. Rename folder (remove -master from the name)
4. Run the game and make sure addon is bein displayed in addon menu

This addon is a set of in-game functions that allows to run class rotation.

To run class rotation you would have to create the following macroses:

#### Fury warrior

```
/run --CastSpellByName("Bloodthirst")
/cast !Attack
/run FuryWarriorDecision(false)
```

#### Arms warrior

```
/run --CastSpellByName("Mortal Strike")
/cast !Attack
/run ArmsWarriorDecision(false)

```

# Enhancement shaman

```
TBD
```

#### Beast Mastery Hunter

```
/run --CastSpellByName("Steady Shot")
/cast !Attack
/run BMHunterDecision(false)
```

#### Marksmanship Hunter

```
/run --CastSpellByName("Steady Shot")
/cast !Attack
/run MMHunterDecision(false, false)
```

Second argument enables **Hunter's Mark** when missing: **first** priority if target HP is above 70%, **last** if at 70% or below. Omit or use `false` to never apply it via the rotation.

```
/run MMHunterDecision(false, true)
```

**Before the combat rotation (runs even with no target):** Trueshot Aura if **not in combat** and the buff is missing → if mana **below 40%**, switch to Aspect of the Viper (when not already active) → if mana **above 95%**, switch to Aspect of the Hawk (when not already active). Between 40% and 95% mana, aspects are left unchanged.

**Rotation priority (without Hunter's Mark):** Concussive Shot (if missing on target) → Arcane Shot → Aimed Shot with Lock and Load → Aimed Shot → Serpent Sting (if missing) → Steady Shot (lowest priority filler).

**With Hunter's Mark enabled:** above 70% HP, Hunter's Mark is checked before Concussive Shot; at 70% or below, it is checked after Steady Shot.

If the Lock and Load buff name differs on your client, edit the string in `mm_hunter.lua` to match the exact tooltip title from `GetBuff`.

**New Abilities:**
- **Baited Shot**: Available for 8 seconds after your pet scores a critical hit
- **Kill Command**: 10 second cooldown, makes your pet's next 2 abilities (Bite/Claw) guaranteed critical hits
- **Pet Ability Management**: Automatically manages pet ability autocast based on energy levels

**Pet Abilities:**
- **Bite**: High damage ability with 6 second cooldown
- **Claw**: Lower damage ability with no cooldown, autocast managed by energy levels

**Pet Energy Management:**
- **>50% Energy**: Claw autocast is ENABLED for consistent damage output
- **<50% Energy**: Claw autocast is DISABLED to conserve energy for important abilities (like Bite when Kill Command is active)

**Rotation Priority:**
1. Auto Attack
2. Tranquilizing Shot (if target enraged)
3. Hunter's Mark
4. Kill Command (when available)
5. Baited Shot (after pet crit)
6. Pet Ability Management (energy-based autocast control)
7. Steady Shot (filler)