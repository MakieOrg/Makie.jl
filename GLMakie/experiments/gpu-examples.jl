using CUDA

const N = 1024  # Number of particles
const dt = 0.01  # Time step
const G = 6.67430e-11  # Gravitational constant
const eps = 1e-3  # Softening factor to avoid singularity


# Struct to represent a particle
struct Particle
    pos::CUDA.CuVector{Point3f}
    vel::CUDA.CuVector{Vec3f}
    mass::CUDA.CuVector{Float32}
end

# Initialize particles with random positions, velocities, and masses
function init_particles(n)
    pos = CUDA.fill(Point3f(0.0f0, 0.0f0, 0.0f0), n)
    vel = CUDA.fill(Vec3f(0.0f0, 0.0f0, 0.0f0), n)
    mass = CUDA.fill(0.0f0, n)

    for i in 1:n
        pos[i] = rand(Point3f) .* 100
        vel[i] = (rand(Vec3f) .- 0.5) .* 10
        mass[i] = rand(Float32) * 10 + 1
    end

    Particle(pos, vel, mass)
end

# GPU kernel to calculate forces and update positions and velocities
function update_particles!(pos, mass, vel, dt, G, eps, N)
    i = threadIdx().x + (blockIdx().x - 1) * blockDim().x
    @inbounds if i <= N
        force = Vec3f(0.0f0, 0.0f0, 0.0f0)
        pos_i = pos[i]

        for j in 1:N
            if i != j
                pos_j = pos[j]
                diff = pos_j - pos_i
                distSqr = sum(diff .* diff) + eps * eps
                invDist = 1.0f0 / sqrt(distSqr)
                invDist3 = invDist * invDist * invDist
                mass_product = mass[i] * mass[j]
                force += diff .* (G * mass_product * invDist3)
            end
        end

        accel = force ./ mass[i]
        vel[i] += accel .* dt
        pos[i] += vel[i] .* dt
    end
    return
end

# Main simulation function
function run_simulation(particles, dt, G, eps, N)
    threads = 256
    blocks = ceil(Int, N / threads)
    @cuda threads = threads blocks = blocks update_particles!(particles, dt, G, eps, N)
end

# Initialize particles
particles = init_particles(N)

# Number of simulation steps
steps = 100

# Run the simulation
run_simulation(particles, dt, steps, G, eps, N)

# Fetch the results from the GPU
positions = Array(pos)
println("Final positions of particles:")
for pos in positions
    println(pos)
end
