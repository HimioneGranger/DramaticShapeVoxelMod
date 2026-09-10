# Release 1.10.6 - performance profiler producer API

Branch `feature/performance-profiler-v2` is versioned 1.10.6 in both `manifest.json` and `mod.exports.version`. Tag `1.10.6` should point at the published producer API commit.

# Performance monitor producer API - 2026-09-10

Branch `feature/performance-profiler-v2` exposes a stable read-only diagnostics
provider at `mod.exports.performance` for the separate `performance-monitor`
project. The monitor owns capture cadence, aggregation, reports and UI; Battle
Art only publishes domain-specific telemetry. No dependency on performance-monitor
was added.

API/schema v1 returns detached snapshots of LoadTimings buckets, RAM/cache state,
structured bounded cache events, ChunkMesher queue/cache pressure, Legendary tree
cache stats, shadow target state and sapling edit counters. Persistent cache
inventory is intentionally separate behind `storageSnapshot()` because it may call
storage.list and should not contaminate high-rate performance samples. See `docs/PERFORMANCE_API.md`.

CacheTrace now records a platform-neutral 64-event structured ring plus monotonic
counters while retaining its existing desktop text log. ChunkMesher exposes only
lightweight scalar/job descriptors; no map, mesh or coroutine ownership escapes.
Focused standalone Fengari validation: `tests/performance_export_test.lua` passes
16 checks; changed Lua files parse and `git diff --check` passes. Native engine
integration with the separate monitor is still required before merging.
# Issue #54 CITY GROUND option - 2026-09-10

Branch `fix/issues54` starts from clean local/remote master `04b8643` (1.10.5).
Issue #54 separates Lavender/Fuchsia city turf from the broad Legendary GRASS
choice. New `CITY GROUND` defaults to `BATTLE ART`; `LEGENDARY VISUALS` keeps
the existing custom city treatment. Lavender's previously unconditional custom
ground now follows this row, while Fuchsia's existing tiled Legendary turf is
selected by CITY GROUND instead of GRASS. Other Overworld maps continue to use
GRASS unchanged. The new row lives under Legendary Visuals > GRASS & TREES and
uses the existing CommunityVisuals live invalidation/persistence path.

City-specific static and animated atlases are map-scoped so Lavender and
Fuchsia cannot reuse one another's baked OVERWORLD animation entry by visit
order. Persistent city terrain fingerprints now include a city-ground contract
token and the CITY GROUND value while ignoring unrelated GRASS changes; other
maps do not gain a CITY GROUND fingerprint dependency. Cache record format is
unchanged, so cache revision remains 37.

Focused standalone validation used the temporary Fengari Lua CLI because this
Windows PATH has no native Lua/LuaJIT executable: `city_ground_option_test.lua`
passes 21 checks (default/ownership matrix, geometry selection, persistent
fingerprints and animated-atlas isolation), `grass_east_edge_test.lua` passes
15, `voxel_build_budget_test.lua` passes 35, and
`voxel_mesh_disk_storage_test.lua` passes 6. All changed Lua files parse and
`git diff --check` passes. `ram_precache_setting_test.lua` cannot run from this
standalone checkout because its engine-side `tests.modkit` fixture is absent.
Native LuaJIT/engine gameplay and actual Lavender/Fuchsia visual comparison are
still required before release. Draft branch is prepared for desktop QA; no deployment or cache-revision bump.

# Local PR #52/#53 integration � 2026-09-09

Branch `codex/legendary-pr52-pr53-integration` starts from the user's local
master `b435d467b55b1c743a13193e794e3dcce5e8b1a2`. Integrated PR #52
`936b23a` and PR #53 `b94eaf3`. Resolved overlapping handoff notes and ignore
rules; production changes merged automatically.

Tower textures, backdrop and mounted-mod/physical-folder ambient audio reads
now use `assets/legendary/`. All 12 supplied PNG/MP3 files are present,
nonempty, ignored and untracked. No media added to source history. The donor's
`lib/` install notes below are historical; use the new path and retain filenames.
`backdrop4.png` is supplied alternate art; the runtime selects `backdrop.png`.
Manifest/mod identity stays at 1.10.5. Cache revision stays 37, with both the
Safari-specific refresh token and v5 auxiliary grass token retained.

Fresh validation: all 128 production Lua files compile under LuaJIT 2.1.
Thirteen existing suites pass (318 counted checks plus Safari wall/stair/foliage
assertions): Legendary cache/UV/settings, grass edges, build budget, disk
storage, Safari, ladders, Cut drop/mesh refresh, restored world hooks, OFF
storage/live hooks, heal overlays and reflections. The Windows harness's
rename-self directory probe prevented mod discovery; reran the two affected
suites with only that probe replaced in memory by a read-only host directory
check. No production or test files changed for this. Asset paths, exclusions,
cache tokens and unchanged manifest (normalizing line endings) verified.
These are headless/mocked checks; Android gameplay, GPU visuals, Tower memory
cost and frame time still require device validation. Earlier reports below
are historical. This integration is local; no remote push or master merge.

# Safari ground coverage and cache refresh � 2026-09-08

Complete olive treatment for flat grass tile94 and hedge/edge variants13,79,84�93.
Only four outdoor Safari atlases change; non-green detail/alpha retained on edges.
Native engine0.2.27 captured all four maps: 567 changed atlas pixels, all outside
new coverage unchanged; tile94 matches tile0 exactly. No Quest validation.
Map-scoped cache token prevents pre-PR51 shrub vertices from surviving the upgrade;
non-Safari fingerprints unchanged. No global cache revision bump.

# TEST138 grass-only integration — 2026-09-09

Applied only the post-TEST137 grass delta from Legendary grass update onto
`Legendary-Updates` at `bcb2f11`. The earlier cave merge is now committed there;
its prior uncommitted status below is historical. Grass changes remain local
and uncommitted, with no push or deployment.

Structures suppresses only exposed east tile-boundary grass caps. VoxelMeshDisk
advances the auxiliary grass fingerprint to v5; combined cache revision 37,
release identity, all other runtime files and assets remain unchanged.

15 focused synthetic geometry/cache checks, 19 existing cave/cache checks,
6 disk-storage checks and the Safari/stair regression pass under LuaJIT.
No Android visual/gameplay check. See
[the grass merge report](docs/LEGENDARY_GRASS_MERGE.md) for scope and evidence.

# Legendary Cave Update integration — 2026-09-09

Merged the supplied Legendary Cave Update into the clean `Legendary-Updates`
checkout at `335bef0`, using verified upstream tag 1.10.3 (`278862b`) as the
three-way base. Changes remain uncommitted; no push or game deployment.
See [the merge report](docs/LEGENDARY_CAVE_MERGE.md) for the file inventory,
conflict decisions, exact validation scope, local media and remaining checks.

Retained newer interface/title, museum/Safari, companion atmosphere, reflection,
heal and Cut integrations. Combined cache streams use revision 37 (new derived
cache build required). Tower defaults to Battle Art; saved Legendary trees keep
full detail and FAST is separate. Supplied PNG/MP3 files remain local in lib/,
excluded from Git; assets/ was not changed. The source input is untouched.

All 128 production Lua files compile. Eighteen standalone/mocked regression
commands pass, including 19 new cache/OFF/UV/setting merge checks. Existing
engine-dependent and real-map cave tests remain unavailable without their
engine/fixtures; Android gameplay and GPU visuals have not been verified here.
Donor TEST102–137 notes and all earlier handoff results remain historical.

# PR #51 merge verification — 2026-09-08

Merged PR head `1e07e7f` into current master `22f5b03` in an isolated worktree.
The merge is conflict-free. Only SafariFoliage.lua, TerrainAtlas.lua and this
handoff change; all other tracked files match the target branch, retaining
restored ladders, heal overlays, water reflections, immediate cut removal,
interface fixes and PR #50 companion atmosphere support.

Fresh Lua 5.1/LuaJIT headless checks passed: cave ladders, heal overlays, water
cast reflection, cut drop/mesh refresh, restored pipeline hooks, precache OFF
policy/integration, Safari walls/stairs/foliage bounds, museum fossils, NATURE
underlay, build budgets, disk storage, interface install/playback (3174 checks
plus 5 modern title checks), atlas decoding, native anchors, companion atmosphere
integration and camera/projection facts. Syntax and whitespace checks pass.
Initial harness working-directory/arg errors were corrected and those suites
rerun successfully. These checks are mocked/headless, not device visual tests.
The PR author's 3.2x shrub geometry cost remains a mobile/Quest performance
limitation; their desktop capture claims above were not repeated in this audit.

# Safari canopy palette and pixel shading — 2026-09-07

Safari shrubs now use fixed one-world-unit surface pixels, connected edge/lower
shadow patches and checkerboard transitions. Color assignment precedes greedy
face merging, preventing stretched texture marks. Voxel occupancy, placements,
collision and draw-call count are unchanged; solid swatches remain 6x1.

The shared FOREST tree canopy receives the existing olive mapping only inside
the four outdoor Safari maps. Bark, alpha and other maps retain their original
colors. Native atlas comparison found 578 changed leaf pixels and no other
pixel changes.

Validation: native desktop engine 0.2.27 paired captures passed without stderr.
The representative Center scene contains 86 shrubs: 266,996 vertices versus
83,564 in the previous material/geometry (about 3.2x). This is the approved visual
prototype, not a Quest performance clearance. Texture-chart optimization should
preserve the approved appearance before a Quest release; Quest/GLES and exact
0.2.53 gameplay have not been tested. No live installation or cache schema change.

# Companion atmosphere extension — 2026-09-07

Optional draft effects API: owner-scoped resources, per-eye queues, bounded
atmosphere state, desktop camera facts and native celestial fallback.
See docs/COMPANION_ATMOSPHERE.md for contract and validation limits.
The official 1.10.4 tree-lift flag no longer falsely blocks registration.
No manifest/cache bump, companion art/runtime, or gameplay changes.

# Requested world-feature restoration — 2026-09-06

Audited the active `DramaticShapeVoxelMod` checkout on local `master` at
`278862b`, loaded by `mods/BATTLE_ART_VOXEL_FORK` through its directory link.
Changes below are local working-tree changes; no commit, push or release made.

## Findings and changes

- PR #41 (`dfc177c`): newer `ladder_up`/`ladder_down` pins bypassed its
  standee geometry. Restored the original `ladder` pins and two-voxel prop
  depth. The newer shaft builder remains available but is not selected by
  the shipped cave ladder pins. This restores the requested source-art
  ladders without changing the game's warp or collision data.
- Heal alignment (`c083147`): `HealOverlay.lua` survived, but main.lua no
  longer called it and Voxel3D no longer exposed the required depth value
  and texture. Restored all three connections, including animation-state
  restoration when field FX throw.
- Player water reflection (`55e195d`): restored the planar cast canvas,
  reflected billboard transform, water-shader compositing and cleanup.
  The existing water setting and readable-depth/canvas fallbacks still apply.
- Immediate cut-tree removal (`7991ccee`): restored prop ownership spans,
  cached span serialization, targeted mesh uploads and the block-edit hook's
  coordinates/map/old-block arguments. Adapted span declarations to the
  current sink order and kept enlarged Legendary tree ownership on its
  authored cell. Unowned border geometry cannot extend a preceding prop run.
  Mesh cache revision is now 32 so pre-restoration records cannot be reused.

The cut fix retains the current terrain and neighbouring map caches and
removes the changed prop immediately. It still marks the edited map for a
budgeted background rebuild, just like the linked commit. This is not a
claim that all rebuild work or every possible frame-time spike is eliminated.
The format/ladder change requires caches to be rebuilt once after upgrading.

## Verification

Run from the engine root with `DS_MOD_PATH=dev/DramaticShapeVoxelMod`:

- `cave_ladder_test.lua`: 38 checks; updated its dead-pin check to recognize
  the newer explicit `sapling_tiles` detector metadata.
- `heal_overlay_test.lua`: 63 checks.
- `water_cast_reflection_test.lua`: 47 checks.
- `cut_drop_test.lua`: 22 checks.
- `restored_world_features_test.lua`: 22 checks covering actual registered
  pipeline calls, heal error recovery, the real Map:setBlock hook, the water
  pass/player transform connection and reflection error recovery.
- `cut_mesh_refresh_test.lua`: 10 checks covering table-sink spans, zeroed
  vertex uploads, retained drawable terrain and unaffected neighbour cache.

Run from the mod root:

- `voxel_build_budget_test.lua`: 35 checks.
- `voxel_mesh_disk_storage_test.lua`: 6 checks.

These are headless/mocked checks using the local LuaJIT/Lua 5.1 runtime, not
in-game visual, GPU-shader or Android performance validation. Lua syntax and
Git whitespace checks also pass.

Broader suites attempted but not passing: `battle_art_voxel_fork_test.lua`
exceeds Lua's 200-local limit; `voxel_visual_object_filter_test.lua` lacks a
CommunityVisuals fixture; `companion_main_uninstall_integration_test.lua`
has a platform fixture without `metalRenderer`. Those suites need separate
harness maintenance. Historical shaft-specific Astra ladder tests describe
the superseded ladder design, rather than this requested PR #41 restoration.

## Follow-up: platform-independent OFF and crash audit

Removed the unsuccessful iOS OFF-to-FULL override. OFF now skips all automatic
voxel cache storage probes/reads, preload planning, and speculative destination
work on every platform. Live geometry still builds cooperatively and its records
remain in session RAM, even without a persistent storage backend. Manual cache
generation/saving remain explicit actions. Added cancellation that preserves jobs
promoted to live terrain, and guarded the remaining direct GC call.

71 cache-policy checks pass, alongside the 243 earlier targeted checks. The map
audit completed Pallet, Route 1 and Celadon geometry against local Yellow data;
Celadon and Route 1 have materially larger geometry footprints than Pallet.
No iOS crash log was available, so memory pressure is a lead, not a confirmed
diagnosis. See `docs/OFF_MODE_CRASH_AUDIT.md` for exact semantics, measurements,
test coverage and the limits of these checks.

## Master integration — 2026-09-07

Fast-forwarded local master from `278862b` to `7743de9`, including PR #47
(museum fossils/cave corners) and PR #48 (Safari scenery/interior textures).
The remote advanced from two to four commits ahead during the fetch.

Reapplied all pending local edits and untracked documentation/tests, including
the user's manifest version `1.10.4`. The sole textual conflict was the cache
revision: upstream used 33 and the local span restoration used 32. The combined
geometry and record format now use revision 34. Local edits remain unstaged and
uncommitted; no push was made. A named safety stash retains the pre-integration
working tree.

The 314 targeted local checks pass on the combined code. Upstream museum,
Safari wall/stair, NATURE underlay, and real-map retaining cave/corner tests
also pass. The real-map test used local Yellow data. Syntax/whitespace and
unmerged-path checks pass; mobile gameplay remains unverified.

## Gen 4 tight atlas migration (2026-09-07)

Inspected `dev/gen4_front_tight-1.10.3` (770 regular/shiny PNG atlases).
Compared every frame against installed originals after a constant per-animation
translation: no altered visible pixels, clipped pixels, or empty frames. All
sheet dimensions match supplied metadata. Species, paths, timings and frame
counts are unchanged. No Unown PNG is supplied (existing metadata also refers
to an absent unown.png).

Merged only frame dimensions into both Gen 4 data tables, retaining original
sizes as legacyLayout. AnimatedBattleArt selects tight or legacy cells by exact
sheet dimensions, so incremental asset overlays remain compatible. No assets
were copied; the owner will overlay supplied assets onto the mod assets folder,
retaining files absent from the pack, then restart. Do not overwrite the merged
data tables with the supplied ones: that removes legacy compatibility.

Keep Summary BATTLE ART fitting: 580/770 opaque animation bounds exceed 56x56;
removing it overlaps name/HP/number UI. Existing fitting already uses scale <=1
and does not downscale artwork whose opaque bounds fit. Cropping preserves the
visible art size, so it cannot eliminate required fitting. Dex uses native
frames and benefits from reduced padding. Runtime/device visual QA remains
outstanding. Decoder and interface playback: 55 checks pass; metadata-only
comparison and Lua syntax checks pass.

## Interface scaling and Android title banding (2026-09-07)

Added INTERFACE SCALING: FIT/FULL (default FIT) beside INTERFACE SPRITES in
POKEMON ART. It applies to BATTLE ART Summary and Dex Image adapters. FIT uses
56x56 opaque-union fitting; FULL uses complete native prepared frames. Switching
is live and retains animation progress. FULL may overlap the stock screen UI.
Title rendering is independent. This supersedes the previous decision to keep
status fitting mandatory; the user explicitly requested FULL as a test option.

Android screenshot (user reports engine 0.2.56) shows horizontal bands on Ditto.
A suspected contributor is fractional display scaling of the title alpha-mask
true-color replay, previously one scissored pass per horizontal pixel run.
Coalesced identical consecutive runs into taller rectangles without changing
covered pixels or trainer exclusion. This reduces internal scissor boundaries
and draw calls, but is a mitigation, not a confirmed Android fix. Engine renderer
also has DPI-aware scissor rounding; device scaling and GPU behavior still need
verification. Ask tester to compare integer display scaling if bands persist.

Mocked interface/title tests: 3169 checks passed, including pixel-by-pixel mask
coverage, trainer occlusion, FIT/FULL live changes, and animation. Lua syntax and
git diff whitespace checks passed. No actual Android/device visual test performed.

## FULL interface anchor correction (2026-09-07)

User screenshots show padded Dewgong/Croconaw frames positioned too low. FULL
now removes shared animation-wide transparent margins and top-aligns visible
art at native resolution in a canvas at least 56x56. Oversized art retains all
pixels and can overlap UI. FIT is unchanged. Shared bounds preserve authored
animation motion. Native and fitted results use separate caches. Synthetic
production-fitter tests verify pixel preservation, top alignment, motion and
cache separation; device visual verification remains outstanding.

## Status centering and installed deployment (2026-09-07)

FULL Summary portraits now center within x=0..71; wider canvases start at x=0
to preserve the left edge. Only the sprite draw and matching true-color mark
move; scoped wrappers restore on errors. FIT remains unchanged. Kanto-Reforged
installed ui/summary_ui.lua labels now use ATK, DEF, SPEED, SPATK, SPDEF to
fit before three-digit values. Companion patch staged separately at
D:/gen1recomp/.codex-temp/interface-deploy/summary_ui.lua.
Compared tracked Battle Art runtime/data/shaders/main/manifest to installed
BATTLE_ART_VOXEL_FORK and copied only differences (2 files); also deployed
1 companion UI file. All copied hashes verified. Backups retained at
D:/gen1recomp/.codex-temp/interface-deploy/backup-20260907-030042.
No asset copying or deletion. Local playback/centering tests passed; in-game
visual verification requires restart.

## FULL Dex vertical centering (2026-09-07)

FULL Dex sprites now center vertically in the 72-pixel portrait area including
the number row, clamped at y=0 for oversized art instead of stock 64-h which
clips the top. Number remains drawn over the sprite as authorized. Matching
true-color marks move with the sprite; FIT is unchanged. 3173 mocked interface
checks and syntax/whitespace checks pass. Deployed InterfaceSprites.lua to the
installed BATTLE_ART_VOXEL_FORK with backup and matching SHA256. Device visual
verification remains outstanding.

## First-pose Dex anchor (2026-09-07)

Per user correction, FULL Dex vertical position now uses the first prepared
frame opaque y0/y1, not maximum animation/canvas height. Subtract first y0
from centered placement, keeping placement constant across animation. Shared
canvas still preserves pixels; it does not determine placement. Status remains
unchanged (user approved Charizard). 3173 mock checks and syntax/whitespace pass.
Deployed InterfaceSprites.lua with backup and SHA256 verification. Actual
animation stretching is not established by the screenshot; native pixels are
not rescaled by this anchor change. Device visual confirmation remains pending.

## Summary first-pose anchor and provider reflections (2026-09-07)

User confirms Android single-image title replay fixed banding and Dex FULL/FIT
looks good. FULL Summary now subtracts first frame opaque y0 from placement,
retaining its approved horizontal centering and native size. No Dex changes.

Found drawCast invoked normal provider drawEntity during reflectPlane pass;
provider models bypass billboardMatrix, so their draw was not mirrored. Added
optional drawReflection callback with reflectionPlane/reflectionRaise context.
Unclaimed reflections use existing mirrored engine sprite; provider art needs
the explicit callback to match its custom appearance in the water. Normal
provider rendering unchanged. Original 55e195d canvas/shader path remains.

Regression checks: water cast 47, heal overlay 63, ladders 38, cut drop 22,
cut refresh 10, restored hooks 22 all pass. Original dfc177c ladder geometry,
c083147 heal overlay alignment, 7991cce immediate prop removal retained.
Cut removal still permits background mesh rebuilding as the original commit
did; this is not a claim that every map rebuild has been eliminated.
Interface checks 3174 plus 5 modern replay checks pass; Lua syntax and whitespace
pass. Deployed InterfaceSprites, CharacterRenderers, VoxelScene with backup
and verified hashes. Phone reflection visual verification remains pending.
Uncommitted; published master/tag not moved.
