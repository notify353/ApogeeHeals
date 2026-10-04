local _, A = ...
-- Owner live testing confirms automatic SetRaidTarget calls are blocked by
-- the Forever client. Keep this installed chunk inert for safe DEV updates;
-- pcall cannot prevent the native blocked-action dialog. No automatic marking,
-- secure-input emulation, event hooks or retry loop is installed here.
A.ThreatMarkers = {}
function A.ThreatMarkers.Start()
end
