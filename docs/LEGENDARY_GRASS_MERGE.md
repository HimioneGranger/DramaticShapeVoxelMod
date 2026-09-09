# TEST138 grass-only merge — 2026-09-09

Target: `Legendary-Updates` at `bcb2f11` (the committed cave/Tower merge).
Input: `C:/Users/User/Desktop/Legendary grass update` (TEST138).
Delta baseline: `C:/Users/User/Desktop/Legendary Cave Update` (TEST137).

Compared every supplied file. Seven files differ from TEST137: Structures,
VoxelMeshDisk, LoadTimings, manifest, README, CHANGELOG and the new TEST138 note.
Only the grass geometry and its cache fingerprint were applied to production:

| File | Applied change |
| --- | --- |
| `lib/Structures.lua` | Mark east tile-boundary caps and omit them only where the adjacent tile is not standing grass under the engine's existing grass-cell rule. |
| `lib/VoxelMeshDisk.lua` | Change auxiliary geometry identity from `closed-tall-grass-v4-camera-safe` to `closed-tall-grass-v5-east-edge-softened`. |

Both three-way merges were conflict-free. Current branch changes in those files
were preserved, including Tower stair metadata and the combined cache format
(revision 37). There is no global cache revision or release-version change.
Diagnostic TEST138 branding and donor manifest/README/CHANGELOG replacements
were excluded. No media or files under assets/ were copied. The source folders
and pre-existing untracked TEST102–137 notes were left intact. No commit or push.

## Checks performed in this checkout

- 15 standalone LuaJIT geometry/cache assertions pass using the actual grass
  builder with synthetic pixels and map inputs. They cover exposed versus
  connected east edges, decorative non-encounter grass, non-boundary caps,
  negative coordinates, exact surviving face/UV/shading equality, and auxiliary
  fingerprint scope. Height/density/animation code is unchanged.
- Existing combined cave/cache regression: 19 checks pass.
- Existing Safari wall/stair/foliage regression passes, including all four
  east/west stair directions and source UV isolation.
- Existing disk-storage regression: 6 checks pass.
- Hash comparison before adding documentation confirms that the only changed
  pre-existing tracked files were the two production files above. All other
  tracked content, including manifest, main, settings and assets, was identical.
- Git whitespace checks pass. The modified modules and the new test load and
  execute under LuaJIT. No Android gameplay or GPU visual verification was run.

The donor's description of the dark-strip fix is historical until visually
confirmed on the user's device. These are synthetic/headless checks, not a
claim of device validation. Changes remain reviewable and uncommitted.
