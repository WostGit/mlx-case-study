import Lake
open Lake DSL

package «pacxai_ci_self_contained_mlx» where
  -- Mathlib-free finite recovery/privacy artifact.

@[default_target]
lean_lib PACXAI where
  roots := #[`PACXAI]
