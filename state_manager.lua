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
    isFiredInstant = false,
    
    -- BM Hunter pet crit tracking and ability management
    lastPetCrit = 0,
    killCommandActive = false,
    killCommandEndTime = 0,
    critsRemaining = 0,
    lastPetBite = 0,
    lastPetClaw = 0,
    petBiteCooldown = 6,
    petClawCooldown = 0,  -- Claw has no cooldown

    -- Hunter Serpent Sting: time-based refresh (see ShouldApplySerpentSting)
    serpentStingTrackedId = nil,
    serpentStingCastTime = nil,
} 