using Makie
using LinearAlgebra

res = 500
game = Scene(resolution = (res, res))
theme(game)[:plot] = NT(raw = true)
campixel!(game)
cell = 10
cells = res ÷ 10
snakelen = 5
middle = cells ÷ 2
snakestart = middle - (snakelen ÷ 2)
segments = Point2f0.(middle, range(snakestart, step = cell, length = snakelen))
snake = scatter!(game, segments, markersize = cell, color = :black, marker = :rect)[end]
global last_dir = (0, 1)
dir = lift(game.events.keyboardbuttons) do but
    global last_dir
    ispressed(but, Keyboard.left) && return (last_dir = (-1, 0))
    ispressed(but, Keyboard.up) && return (last_dir = (0, 1))
    ispressed(but, Keyboard.right) && return (last_dir = (1, 0))
    ispressed(but, Keyboard.down) && return (last_dir = (0, -1))
    last_dir
end
newsnake = copy(segments)

food = scatter!(game, [Point2f0(res .÷ 2)], markersize = 2cell, marker = '☕')[end]

function run_game(game, snake, newsnake, food)
    display(game)
    spawntime = time()
    newspawn = 6
    speed = 1/10
    while isopen(game)
        curr_snake = snake[1][]
        circshift!(newsnake, curr_snake, 1)
        newsnake[1] = newsnake[2] .+ Point2f0(dir[] .* cell)
        spawndiff = time() - spawntime
        if spawndiff > 0
            if (newspawn - spawndiff) < 0.1 && (newspawn - spawndiff) > 0
                food[1][][1] = Point2f0(rand(1:cells), rand(1:cells)) .* cell

            elseif (newspawn - spawndiff) < 0.1
                food[1][][1] = Point2f0(res + cell)
                food[1][] = food[1][] # update array
                spawntime = time()
            end
        end
        if norm(newsnake[1] .- food[1][]) < 3cell
            snake[:color] = :red
            food[1][][1] = Point2f0(res + cell)
            # append segments to snake
            a, b = newsnake[end], newsnake[end - 1]
            push!(newsnake, a .+ (b .- a))
            push!(curr_snake, Point2f0(0))
            speed = speed - (speed * 0.5)
            spawntime = time()
        else
            snake[:color] = :black
        end
        food[1][] = food[1][] # update array
        snake[1] = newsnake
        newsnake = curr_snake
        sleep(speed);
        force_update!()
    end
end
run_game(game, snake, newsnake, food)

scene = Scene()

display(scene);
