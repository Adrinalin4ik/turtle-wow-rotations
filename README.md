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

Aligned with the Marksmanship flow (aspects, Concussive rules, Arcane before Serpent, Steady filler) plus BM-specific skills.

```
/run --CastSpellByName("Steady Shot")
/cast !Attack
/run BMHunterDecision(false, false, false, false)
```

Arguments: **`debugEnabled`**, **`manageHuntersMark`** (same HP rules as MM), **`useBestialWrath`** (cast when ready and buff not up), **`petAttack`** (call `PetAttack` on the target). Example with Hunter's Mark + Bestial Wrath + pet attack:

```
/run BMHunterDecision(false, true, true, true)
```

**Aimed Shot** is only used if **Aimed Shot** is on an action bar slot (addon mapping from `PopulateSpellToActionMapping`), so untalented BM skips it.

**Combat priority:** Kill Command → Bestial Wrath (if flag) → Hunter's Mark (high, if flag) → Concussive Shot → Arcane Shot → Aimed (if on bar, Lock and Load then normal) → Serpent Sting (15s timer after your cast per target; reset on target change; reapplies if debuff missing) → Steady Shot → Hunter's Mark (low, if flag).

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

**Rotation priority (without Hunter's Mark):** Concussive Shot (if missing on target) → Arcane Shot → Aimed Shot with Lock and Load → Aimed Shot → Serpent Sting (15s after your cast per target; if Serpent debuff is missing on target, refresh is allowed regardless of timer) → Steady Shot (lowest priority filler).

**With Hunter's Mark enabled:** above 70% HP, Hunter's Mark is checked before Concussive Shot; at 70% or below, it is checked after Steady Shot.

If the Lock and Load buff name differs on your client, edit the string in `mm_hunter.lua` to match the exact tooltip title from `GetBuff`.

**Kill Command** is the top combat skill in the BM script when off cooldown and usable.