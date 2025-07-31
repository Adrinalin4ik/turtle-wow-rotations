-- Combined state for all classes
CurrentState = {
    debugEnabled = false,
    lastDodge = 0,
    lastParry = 0,
    skillCastTimes = {},  -- Format: {[spellName] = timestamp}
    lastAutoAttack = 0,
    autoShotActive = false,
    lastSpellCastStop = 0,
    -- Quiver-style auto shot state
    isShooting = false,
    isReloading = false,
    shootStartTime = 0,
    reloadStartTime = 0,
    rangedSpeed = 0,
    isCasting = false,
    isFiredInstant = false
} 