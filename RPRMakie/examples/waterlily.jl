using WaterLily, RPRMakie, ProgressMeter
using LinearAlgebra: norm2

function TGV(p=6,Re=1e5)
    # Define vortex size, velocity, viscosity
    L = 2^p; U = 1; ν = U*L/Re

    # Taylor-Green-Vortex initial velocity field
    function uλ(i,vx)
        x,y,z = @. (vx-1.5)*π/L                # scaled coordinates
        i==1 && return -U*sin(x)*cos(y)*cos(z) # u_x
        i==2 && return  U*cos(x)*sin(y)*cos(z) # u_y
        return 0.                              # u_z
    end

    # Initialize simulation
    return Simulation((L+2,L+2,L+2),zeros(3),L;U,uλ,ν)
end

function ω_mag_data(sim)
    # plot the vorticity modulus
    @inside sim.flow.σ[I] = WaterLily.ω_mag(I,sim.flow.u)*sim.L/sim.U
    return @view sim.flow.σ[2:end-1,2:end-1,2:end-1]
end

sim = TGV()
data_func = ω_mag_data
duration = 10
step = 0.5
# function volume_video!(sim,data_func;name="file.mp4",duration=1,step=0.1)
# Set up viz data and figure
dat = Observable(data_func(sim))

fig, ax, plt = Makie.volume(
    dat,
    colorrange = (π,4π),
    algorithm = :absorption,
    absorption = 1f0,
);

# Run simulation and update figure data
t₀ = round(WaterLily.sim_time(sim))
t = range(t₀, t₀ + duration; step)
record(ax.scene, "waterlily_rpr.mp4", backend = RPRMakie, iterations = 10) do io
    @showprogress for tᵢ in t
        sim_step!(sim,tᵢ)
        dat[] = data_func(sim)
        recordframe!(io)
    end
end