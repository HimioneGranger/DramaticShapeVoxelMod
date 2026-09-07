# Companion atmosphere effects (draft)

Optional capability: atmosphere_effects_draft = 1.
Register through exports.voxel_companion, require this capability, and call
handle:effects(). Reacquire after invalidation. Revoked resources cannot be reused.
This is a trusted installed-mod API, not an execution sandbox for untrusted GLSL.

## Ownership

Battle Art owns scene order, per-eye matrices, depth, camera and fallback.
Extensions own their GLSL, geometry, pixels, simulation and audio.
No Weather or Horizons assets/runtimes are included.
Queue commands during companion update: simulate once, draw for each eye.
Queues clear each update. Graphics state is restored after each effect.

## Facade (colon methods)

- material{source, uniforms={}, skyDepth=false}: GLSL up to 64 KiB. Defaults
  support booleans, finite numbers and flat vectors. vp/eye are reserved host
  uniforms, rebound each draw. Sky depth clamps far depth without changing terrain.
- mesh{format, vertices}: float triangle attributes including VertexPosition.
- updateMesh(token, vertices): same vertex count; recreate when the count changes.
- image{width,height,rgba,wrap}: RGBA8, nearest filtering, repeat (default) or
  clamp; maximum 2048 per dimension.
- enqueue{phase,material,mesh,image,uniforms,blend,tint}: phases
  celestial_before_clouds, sky_deck, translucent_after_actors.
  Blend alpha/add uses alphamultiply; tint is RGBA. Uniform overrides must have
  defaults. Sky materials cannot use the late phase. Depth lequal, no writes.
- submitAtmosphere{sky,tint,haze}: bounded sky dim/flash, world
  multiplier/additive tint and haze density/color. sky.replaceCelestials defers
  the native body only with a valid owned draw. Failed replacement draws the
  native body behind foreground terrain. Water suppresses its native body only
  after successful replacement.
- camera(): copied last-completed desktop center camera with frame age, map/mode,
  eye/focus/basis, near/far/FOV. Stale or changed identity returns unavailable.
  Raw stereo/external eyes are not treated as center-camera facts.
- release(token), clear(): release resources or clear queued/state contributions.

Per-owner budgets: 24 materials, 24 meshes, 8 images, 131072 vertices,
16 MiB resources, 8 MiB uploads/update, 128 draws.
Aggregate: 32 materials, 262144 vertices, 32 MiB.
Faults revoke the failing owner only.

No-provider values stay neutral. Stock sky behavior remains unchanged without a
provider, including its legacy-uniform fallback. With a provider, optimized-out
legacy uniforms no longer prevent dim/flash uploads. The reference
VoxelCompanionAPI dispatcher is unchanged.

## Integrity correction

Official 1.10.4 Structures.lua contains __ds_tree_lift, so that flag alone is
no longer evidence of a legacy KFP splice. Other marker checks remain.
The compared source was byte-identical to the release, SHA256
7f4c602651b298783ca5800314e770591e2d6f424534d4caedf619b9c5c43192.

## Verification and limits

Portable LuaJIT tests (run from mod root):
- tests/atmosphere_camera_test.lua
- tests/atmosphere_camera_projection_test.lua
- tests/atmosphere_companion_integration_test.lua

Separate private integration evidence: engine 0.2.24, 1200 frames through clear,
rain, night, snow and storm, including NightSky runtime, no companion errors.
Eight original effect paths had zero RGBA differences in native GPU comparisons.
Cloud source compiled/rendered; full cloud reference parity was not established.
The companion adapter/artwork are intentionally separate from this PR.
Native tests also covered per-eye VP rebinding, owner isolation, celestial
fallback/occlusion, stock-sky parity, and blend/tint/wrap state restoration.

The API remains draft. Quest/GLES, stereo center-camera acquisition, ray/axis
sky replacement and exact engine 0.2.53 gameplay remain unverified.
The broad existing voxel_companion_api_v1_test suite fails on the baseline
(observedAfterMutation nil); it is not counted as passing.
