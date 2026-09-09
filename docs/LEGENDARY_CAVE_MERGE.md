# Legendary Cave Update merge — 2026-09-09

## Comparison and result

- Target: `Legendary-Updates`, starting at `335bef0` (1.10.5). Initial working tree was clean.
- Base: upstream tag `1.10.3`, verified using upstream tag refs as `278862b063e78c73d080e01452c707be0e24a74f`. The fork itself has no published tags.
- Input: `C:/Users/User/Desktop/Legendary Cave Update`, labelled 1.10.3-test137.
- Applied as reviewable, uncommitted working-tree changes on the requested branch. No reset, deletion, branch switch, commit, push, or installed-game deployment.
- Three-way comparison: 183 supplied files; 89 unchanged from the base, 45 new text files, 17 clean text merges, six conflicted text files, and 12 supplied media files.
- Files absent from the supplied folder were retained. All 89 base-identical files retain the target branch content; the 1.10.5 manifest and mod identity remain byte-equivalent after newline normalization.

## Included changes

Cave rock/dirt materials, cave details/audio, Tower walls/materials/sconces/fog and controls, forest/sky/sign/tree presentation, loading instrumentation, placement-cache optimization, and battle presentation integrations. The folder contains a broader Legendary update, not just cave geometry. Existing timing instrumentation starts hidden.

## Resolutions and compatibility

| File | Resolution |
| --- | --- |
| `main.lua` | Keep session-only cache policy and beginSession; combine the new isolated Legendary sapling path with the existing coordinate-aware Cut refresh fallback; retain heal/UI/provider hooks. |
| `lib/ChunkMesher.lua` | Combine registry/sign caches and tree optimization with authored-cell prop ownership, live Cut spans, and grass/flower spans. Correct supplied Tower auxiliary UVs from an obsolete 512px layout to the actual 3200×4096 layout. |
| `lib/VoxelMeshDisk.lua` | Serialize and decode both visual/registry records and prop spans; retain OFF-mode and missing-storage guards. Revision 37 invalidates both incompatible parent formats. |
| `lib/Structures.lua` | Keep current atlas-safe stair subdivision and source tile metadata; add Tower material metadata without resurrecting the obsolete fallback face. |
| `lib/Voxel3D.lua` | Retain companion weather uniforms and add the separate forest fog uniforms. |
| `manifest.json` | Keep target 1.10.5 manifest unchanged. |

Tower defaults to Battle Art for existing branch users; an explicitly saved Legendary selection remains supported. Existing saved `communityTrees=n64memory` retains full tree detail; the lighter recipe uses the new `n64memory_fast` selection. Cave/forest/sky defaults remain opt-in. Audio reads the active mod first, with only its own physical-folder fallback; incoming searches of other mods and shared path globals were removed.

## Media and assets

No changes were made under `assets/`. The 12 supplied PNG/MP3 files are installed locally under `lib/`, hash-verified against the source folder, and explicitly ignored by Git. They are not included in source changes. A separate runtime media overlay is required when distributing source elsewhere. The original update folder is untouched.

## Validation performed here

- All 128 production Lua files compile under LuaJIT 2.1 (isolated Lupa runtime).
- 18 standalone/mocked regression commands pass: build budgets; disk storage; Safari walls/stairs/foliage; museum fossils; NATURE underlay; native interface anchors; interface/title playback (3176 + 5 checks); companion atmosphere; camera facts/projection; Stadium circle depth/background/model APIs; battle sidecars (37 checks); battle UI; trainer selection/visibility; combined merge regression (19 checks).
- The new merge regression exercises actual cache serialization with a mocked codec/storage backend: sign streams, registries and Cut spans coexist; OFF avoids disk reads/scans; explicit save and normal-mode reload work. It also checks actual auxiliary UV scaling, Cut owner selection and saved-setting compatibility.
- Updated existing test mocks for added optional modules and timing instrumentation. Assertion-only replacement for the absent engine test harness was used in attempted engine-dependent tests; no engine runtime was simulated.
- Engine-dependent ladder/Cut/OFF suites and historical Astra cave geometry/placement suites could not run because the engine source, harness/runtime and map fixtures are not present. Their earlier handoff results are historical, not results of this merge. The new standalone merge test covers cache/OFF serialization and owner-range selection but does not replace those integration checks.
- Whitespace, conflict-marker, branch, preserved-file, manifest, media hash/exclusion and no-deletion checks pass.

## Remaining verification

Run with the actual Gen1Recomp 0.2.53 setup: cave entrances/slopes/ladders, Tower OFF/ON and all materials/fog tiers, Cut/regrowth/map crossings with cache OFF and enabled, water/provider reflections, capture effects, naming screen and optional-companion absence. Actual Android GPU/shader behavior, visuals and frame time are unverified. The expanded Tower atlas has a material memory cost that needs device checking. No ROM or generated imported model pack was added.

## Historical input notes

Imported `docs/TEST102.md` through `docs/TEST137.md` (only files supplied) and their CHANGELOG entries describe the donor build. Their screenshots, approval wording, test counts and install/version instructions are historical and were not independently reproduced here. This report supersedes their default/version instructions for the merged branch.

## Supplied text differences

| Path | Three-way result |
| --- | --- |
| `CHANGELOG.md` | merged |
| `data/battle_arenas.lua` | merged |
| `data/map_atmosphere.lua` | new |
| `data/voxel_heights.lua` | merged |
| `docs/TEST102.md` | new |
| `docs/TEST103.md` | new |
| `docs/TEST104.md` | new |
| `docs/TEST105.md` | new |
| `docs/TEST109.md` | new |
| `docs/TEST110.md` | new |
| `docs/TEST111.md` | new |
| `docs/TEST112.md` | new |
| `docs/TEST113.md` | new |
| `docs/TEST114.md` | new |
| `docs/TEST115.md` | new |
| `docs/TEST116.md` | new |
| `docs/TEST117.md` | new |
| `docs/TEST118.md` | new |
| `docs/TEST119.md` | new |
| `docs/TEST120.md` | new |
| `docs/TEST121.md` | new |
| `docs/TEST122.md` | new |
| `docs/TEST123.md` | new |
| `docs/TEST124.md` | new |
| `docs/TEST125.md` | new |
| `docs/TEST126.md` | new |
| `docs/TEST127.md` | new |
| `docs/TEST128.md` | new |
| `docs/TEST129.md` | new |
| `docs/TEST130.md` | new |
| `docs/TEST131.md` | new |
| `docs/TEST132.md` | new |
| `docs/TEST133.md` | new |
| `docs/TEST134.md` | new |
| `docs/TEST135.md` | new |
| `docs/TEST136.md` | new |
| `docs/TEST137.md` | new |
| `lib/Backdrop.lua` | new |
| `lib/BattleArena.lua` | merged |
| `lib/BattleCam.lua` | merged |
| `lib/BattleScene.lua` | merged |
| `lib/CaveAtmosphere3D.lua` | new |
| `lib/CaveSconces.lua` | new |
| `lib/ChunkMesher.lua` | conflict |
| `lib/CommunityFlora.lua` | merged |
| `lib/CommunityVisuals.lua` | merged |
| `lib/FirstPerson.lua` | merged |
| `lib/ForestAtmos.lua` | new |
| `lib/ForestDressing.lua` | new |
| `lib/LoadTimings.lua` | new |
| `lib/OverworldBattle.lua` | merged |
| `lib/SaplingEdits.lua` | new |
| `lib/ShadowMap.lua` | merged |
| `lib/Sky.lua` | merged |
| `lib/SkyLayer.lua` | new |
| `lib/StadiumBackground.lua` | merged |
| `lib/Structures.lua` | conflict |
| `lib/TerrainAtlas.lua` | merged |
| `lib/TileShape.lua` | merged |
| `lib/TowerFogSettings.lua` | new |
| `lib/TowerGraveMist.lua` | new |
| `lib/TowerLobbyDetails.lua` | new |
| `lib/Voxel3D.lua` | conflict |
| `lib/VoxelMeshDisk.lua` | conflict |
| `lib/VoxelScene.lua` | merged |
| `main.lua` | conflict |
| `manifest.json` | conflict |
| `README.md` | merged |
