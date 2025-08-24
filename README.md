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