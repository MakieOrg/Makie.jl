# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

## Documentation Structure

The Makie documentation uses Documenter.jl and is organized into several sections:

### Content Organization (src/)
- **index.md**: Landing page with feature overview
- **get-started.md**: Installation and first steps
- **explanations/**: Conceptual documentation
  - **backends.md**: Backend comparison and selection
  - **scenes.md**: Scene graph and rendering
  - **blocks.md**: Layout system and UI components
  - **layouting.md**: GridLayout details
  - **colors.md**: Color handling and palettes
  - **fonts.md**: Font system and text rendering
- **tutorials/**: Step-by-step guides
- **how-to/**: Task-specific instructions
- **reference/**: API documentation
  - **plots/**: All plot types
  - **blocks/**: All layout blocks
  - **api.md**: Function reference

### Building Documentation

```bash
cd docs
julia --project make.jl

# Serve locally
julia --project -e 'using LiveServer; serve(dir="build")'
```

### Documentation Deployment
- Built automatically via GitHub Actions
- Deployed to GitHub Pages
- Stable and dev versions maintained

## Writing Documentation

### Plot Examples
```julia
# docs/src/examples/plots/scatter.jl
using CairoMakie

f = Figure()
scatter(f[1, 1], randn(100), randn(100))
save("scatter.png", f)  # Auto-included in docs
```

### Adding New Pages
1. Create `.md` file in appropriate section
2. Add to `pages` in `make.jl`
3. Include examples and cross-references

### Style Guidelines
- Use `@docs` blocks for API documentation
- Include visual examples for all plots
- Provide both simple and advanced examples
- Cross-reference related concepts

## Common Documentation Tasks

### Adding a New Plot Type
1. Create example in `docs/src/reference/plots/newplot.jl`
2. Document in `docs/src/reference/plots/newplot.md`
3. Add to navigation in `make.jl`

### Updating Examples
```julia
# Run specific example
include("docs/src/examples/tutorials/basic_tutorial.jl")

# Update all examples
include("docs/generate_manual.jl")
```

### Creating Tutorials
1. Write as Literate.jl file if complex
2. Or standard Markdown with code blocks
3. Test all code examples work

## Documentation Generation

### Literate.jl Integration
Some tutorials use Literate.jl for:
- Executable documentation
- Automatic plot generation
- Notebook export

### Example Generation
- `generate_manual.jl`: Creates example images
- Examples run during doc build
- Images saved to `docs/src/assets/`

### Reference Generation
- Extracts docstrings from source
- Generates plot type galleries
- Creates attribute tables

## Important Files

### Setup and Configuration
- **make.jl**: Main documentation builder
- **Project.toml**: Documentation dependencies
- **generate_manual.jl**: Example generator

### Templates and Assets
- **assets/**: CSS, logos, custom JS
- **src/_css/**: Custom styles
- **src/_layout/**: Page templates

### Content Files
- **changelog.md**: Version history
- **ecosystem.md**: Related packages
- **faq.md**: Common questions

## Tips for Contributors

1. **Test Locally**: Always build docs locally before PR
2. **Visual Examples**: Include plots for visual functions
3. **Cross-References**: Link related concepts
4. **Version Notes**: Mark version-specific features
5. **Performance Tips**: Include where relevant

## Documentation Deployment

The documentation is automatically:
1. Built on every PR (preview)
2. Deployed on merge to master (dev)
3. Tagged for releases (stable)

Access at:
- Stable: https://docs.makie.org/stable
- Dev: https://docs.makie.org/dev