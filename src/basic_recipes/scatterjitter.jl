"""
scatterjitter(x,y; jitter_type=true, jitter_width=1, clamped_portion,kwargs...)
Plot a scatter plot, but jitter points along the x-axis.

# Arguments
- `x/y`, same as for `Scatter`
# Keywords
- `jitter_type=:pseudorandom`: Type of jitter. Available are `:pseudorandom` (follows the deterministic VanDerCorput series, weighted by the kernel-estimated-density), `:quasirandom` (uniform jitter, but weighted by the kernel-estimated-density density) or `:uniform`
- `jitter_width=1`: How much to jitter left/right
- `clamped_proportion=0`: Optionally clamp the values left/right by a certain amount of jitter_width


Benedikt Ehinger & Vladimir Mikheev
"""
@recipe(ScatterJitter,x,y) do scene
        return Attributes(
            jitter_type=:pseudorandom,
            jitter_width = 1,
            clamped_portion = 0.;
            default_theme(scene, Scatter)...
        )
end

function plot!(plt::ScatterJitter)    
    jitter = map(x->create_jitter_array(x; 	jitter_type=to_value(plt.jitter_type),jitter_width=to_value(plt.jitter_width),clamped_portion=to_value(plt.clamped_portion)), plt.y)
    
    scatter_x = map(+,plt.x,jitter)
    
    scatter!(plt,Attributes(plt),scatter_x,plt.y,)
    return plt
end
# Allow to globally set jitter RNG for testing
# A bit of a lazy solution, but it doesn't seem to be desirably to
# pass the RNG through the plotting command
const JITTER_RNG = Ref{Random.AbstractRNG}(Random.GLOBAL_RNG)

# quick custom function for jitter
jitter_uniform(n) = jitter_uniform(JITTER_RNG[],n)
jitter_uniform(RNG::Random.AbstractRNG, n) = rand(RNG,n)

function create_jitter_array(data_array; jitter_type = :uniform,jitter_width = 1, clamped_portion = 0.0)
    jitter_width < 0 && ArgumentError("`jitter_width` should be positive.")
    !(0 <= clamped_portion <= 1) || ArgumentError("`clamped_portion` should be between 0.0 to 1.0")

    # Make base jitter, note base jitter minimum-to-maximum span is 1.0
    base_min, base_max = (-0.5, 0.5)

	
	if jitter_type == :uniform
		#pdf_x = ones(length(data_array))
		jitter = jitter_uniform(length(data_array))
		
	elseif jitter_type == :pseudorandom
		jitter = jitter_uniform(length(data_array))
		
	elseif jitter_type ==:quasirandom
		jitter = vandercorput.(1:length(data_array))
	else
	
		error("jitter_type not implemented")
	
	end
	jitter = jitter.*(base_max-base_min).+base_min
	
	# weight it
	if jitter_type == :pseudorandom || jitter_type == :quasirandom
	
		k = KernelDensity.kde(data_array,npoints=200)	
		ik = InterpKDE(k)
		pdf_x = pdf(ik, data_array)
		pdf_x = pdf_x ./ maximum(pdf_x)
		jitter = pdf_x .* jitter
	end

	
    # created clamp_min, and clamp_max to clamp a portion of the data
    @assert (base_max - base_min) == 1.0
    @assert (base_max + base_min) / 2.0 == 0
    clamp_min = base_min + (clamped_portion / 2.0)
    clamp_max = base_max - (clamped_portion / 2.0)

    # clamp if need be
    clamp!(jitter, clamp_min, clamp_max)

    # Based on assumptions of clamp_min and clamp_max above
    jitter = jitter * (0.5jitter_width / clamp_max)
	
    return jitter
end

