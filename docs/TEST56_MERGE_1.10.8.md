# TEST56 merge into 1.10.8

Merged locally on 2026-09-11 from `C:\Users\User\Desktop\Test56` into
branch `1.10.8`, starting at `170f0c8`. No commit, tag, deployment, or push.
The package version remains 1.10.7; the donor has no manifest.

## Merge method and preservation

Compared donor files with current source and used `5e1d267` as a three-way
comparison checkpoint. This checkpoint was inferred from history and donor
notes, not established as the exact donor release base. Resolved overlapping
changes individually. Kept current version surfaces, tree-detail submenu,
Battle Art Lavender lawn/path materials, and the Route 10 exit-lawn correction.
The new interior switches default to Battle Art; existing saved selections
remain effective. Source Test56 was not modified.

Integrated donor room geometry/materials, Lavender garden and lamps, cliff
masonry, item Pokeballs, capture/audio modules, native Fly presentation, and
associated renderer changes. Removed donor drawing from the renderer capability
query. Clear map-local street lamps at scene end to prevent lighting carryover.

## Options

Under LEGENDARY VISUALS on the modern submenu API:

| Submenu | Controls |
| --- | --- |
| GAME CORNER | Casino and prize room |
| LAVENDER & CITIES | City ground, including Legendary Lavender garden/paving/lamps |
| INTERIORS | Underground tunnels, Rocket Hideout, elevator |

Existing nature/tree-detail and other categories remain. Lavender street color
follows the existing Pokemon Tower wall-style control, as in the donor. Older
supported menu APIs retain the existing fallback. Capture settings use the
donor's Ember Legacy grouping.

## Local assets

All 12 supplied Legendary PNG/MP3 files are in `assets/legendary/`. Removed
the old duplicate media files from `lib/` only after verifying identical copies
at their destination. Copied 32 capture OGG files to
`assets/legendary/ember-legacy/poke_ball/` and updated the audio loader.
All 44 destination files match Test56 SHA-256 hashes. No media files remain
in `lib/`, and no Lua media references to `lib/` remain. Legendary media remains
Git-ignored and must be supplied separately when installing. General artwork,
ROMs, imported packs, and donor reference files were not added to source.
Concurrent user edits to `.gitignore` were preserved.

## Explicit limitation

Did not import `FlyHosted.lua` or its `StadiumBackground.lua` integration:
the donor replaces companion methods directly. Kept the existing public-provider
hosted behavior; the supported companion extension API/source is missing.
Native Battle Art Fly presentation is included.

## Validation in this checkout

- LuaJIT compilation: 151 production/data Lua files, zero errors.
- All 18 available standalone regression suites passed, including renderer
  sidecars, Stadium bridges, interface, caves, terrain and atmosphere checks.
- Interior/submenu integration: 91 assertions passed, including defaults,
  independent toggles, bounded geometry, altered-layout fallbacks and map guards.
- City ground: 55 assertions passed; Lavender approach: 216 assertions passed.
- Media hashes and whitespace checks passed.

Tests use LuaJIT with mocks/synthetic maps. Engine-dependent suites were not
available in this environment. No Android gameplay or visual verification was
performed; check the six requested locations, capture effects/audio and Fly
in Gen1Recomp 0.2.53 before release.
