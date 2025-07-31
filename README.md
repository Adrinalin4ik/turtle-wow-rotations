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