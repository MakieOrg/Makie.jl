# SDF Brickmap Benchmark: V0 vs V1

resolution=512 (N_blocks=73, bricksize=8). RX 7900 XTX for GPU.

- **V0** - `update_brickmap!` in csgplot.jl (dynamic dispatch on Symbols)
- **V1 CPU** - `gpu_update_brickmap!` in csgplot-gpu.jl (static dispatch, KernelAbstractions CPU())
- **V1 GPU** - same code, KernelAbstractions ROCBackend()

## Common bounding box [-1,1]^3

|                | V0 CPU     | V1 CPU     | V1 GPU     |
|----------------|------------|------------|------------|
| Simple         | 81 ms      | 137 ms     | 92 ms      |
| Gear           | 336 ms     | 260 ms     | 148 ms     |
| Complex        | 526 ms     | 399 ms     | 231 ms     |

## Tight bounding box (as csgplot uses)

|                | V0 CPU     | V1 CPU     | V1 GPU     |
|----------------|------------|------------|------------|
| Simple         | 296 ms     | 494 ms     | 322 ms     |
| Gear           | 2495 ms    | 1562 ms    | 841 ms     |
| Complex        | 1313 ms    | 932 ms     | 538 ms     |

Tight bb makes gear especially slow: the gear is very flat (z width 0.2 vs xy width 1.87),
so the tight bb maps 73 z-blocks onto 0.2 units, making all 73^3=389k bricks intersect
the surface. Common bb [-1,1]^3 spreads the geometry across a larger grid so most bricks
get culled early.

V1 GPU speedup over V0 CPU: 2-3x (common bb), up to 3x (tight bb gear).
V1 GPU runtime includes CPU<->GPU transfer and CPU-side brick management.
