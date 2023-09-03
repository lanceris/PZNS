--- Cows: Placeholder flags for main options / sandbox options...
-- IsDebugModeActive = true;
-- IsInfiniteAmmoActive = true;
-- IsNPCsNeedsActive = false;
-- IsPVPActive = false;
-- GroupSizeLimit = 8;
require("00_references/init")

PZNS.Options.NPCAIUpdateRateByState = {
    Companion = 20,
    Guard = 250,
    ["Wander In Cell"] = 200,
    HighThreat = 5,
    MediumThreat = 20
}
