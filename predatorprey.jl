include("sim.jl")
include("render.jl")

struct GameEnvironment <: Abstract2DEnvironment
    width::Float64
    height::Float64
end

getsize(env::GameEnvironment) = (env.width, env.height)

mutable struct Plant <: AbstractPositionEntity
    x::Float64
    y::Float64
    enabled::Bool
end

colorof(plant::Plant) = plant.enabled ? 2 : 3

getposition(plant::Plant) = [plant.x, plant.y]

function step!(plant::Plant, scene::Scene{W,E}) where {W <: Tuple,E}
    # Create a plant randomly around this one
    if !plant.enabled
        if rand() < 0.001
            plant.enabled = true
        end
        return
    end

    nearby = inrange(scene, plant, 6)    

    numplants = 0

    for (i,type) in enumerate(W.types)
        if type == Vector{Plant}
            numplants = length(nearby[i])
        end
    end 

    numplants -= 1

    prob = 1.0 - numplants / 5.0

    if prob <= 0.0
        prob = 0.0
        plant.enabled = false
    end

    if (rand() < prob/8)
        dir = rand() * 2 * pi
        x = plant.x + cos(dir) * 5
        y = plant.y + sin(dir) * 5
        if x > 300
            x = 300
        end
        if y > 300
            y = 300
        end
        if x < 0
            x = 0
        end
        if y < 0
            y = 0
        end
        newplant = Plant(x, y, true)
        push!(scene, newplant)
    end

end

mutable struct Bunny <: AbstractDirectionalEntity
    x::Float64
    y::Float64
    dx::Float64
    dy::Float64
    life::Int64
    food::Int64
end

colorof(::Bunny) = 14

function Bunny(x::Float64,y::Float64)
    Bunny(x,y,1,1,rand(100:600),0)
end

getposition(bunny::Bunny) = [bunny.x, bunny.y]

getdirection(bunny::Bunny) = [bunny.dx, bunny.dy]

function setdirection!(bunny::Bunny, dir::Vector{Float64})
    bunny.dx, bunny.dy = dir
    if norm(dir) == 0
        bunny.dx = 1
        bunny.dy = 0
    end
end

function setposition!(bunny::Bunny, pos::Vector{Float64})
    bunny.x, bunny.y = pos
end

function step!(bunny::Bunny,scene::Scene{W,E}) where {W <: Tuple,E}

    if bunny.life <= 0
        delete!(scene, bunny)
    end
    bunny.life -= 1

    if bunny.food >= 55
        bunny.food = 0
        push!(scene, Bunny(bunny.x+1, bunny.y+1))
    end

    inrange = inrangesorted(scene, bunny, 20.0)

    for (i,type) in enumerate(W.types)
        if type == Vector{Wolf}
            for wolf in inrange[i]
                lookaway!(bunny, wolf)
                moveforward!(bunny, 1)
                dist = distance(bunny, wolf)
                return
            end
            break
        end
    end 

    for (i,type) in enumerate(W.types)
        if type == Vector{Bunny}
            for otherbunny in inrange[i]
                if otherbunny == bunny
                    continue
                end
                lookaway!(bunny, otherbunny)
                moveforward!(bunny, 1)
                return
            end
        end
    end 

    for (i,type) in enumerate(W.types)
        if type == Vector{Plant}
            for plant in inrange[i]
                lookat!(bunny, plant)
                moveforward!(bunny, 1)
                dist = distance(bunny, plant)
                if dist < 5.0
                    bunny.food += 1
                    delete!(scene, plant)
                end
                return
            end
        end
    end 
end

mutable struct Wolf <: AbstractDirectionalEntity
    x::Float64
    y::Float64
    dx::Float64
    dy::Float64
end

colorof(::Wolf) = 8

getposition(wolf::Wolf) = [wolf.x, wolf.y]

getdirection(wolf::Wolf) = [wolf.dx, wolf.dy]

function setdirection!(wolf::Wolf, dir::Vector{Float64})
    wolf.dx, wolf.dy = dir
end
    
function setposition!(wolf::Wolf, pos::Vector{Float64})
    wolf.x, wolf.y = pos
end

function step!(wolf::Wolf,scene::Scene{W,E}) where {W <: Tuple,E}
    inrange = inrangesorted(scene, wolf, 300/3.0)

    for (i,type) in enumerate(W.types)
        if type == Vector{Wolf}
            for otherwolf in inrange[i]
                if otherwolf == wolf 
                    continue
                end
                lookaway!(wolf, otherwolf)
                moveforward!(wolf, 1)
                return
            end
            break
        end
    end

    for (i,type) in enumerate(W.types)
        if type == Vector{Bunny}
            for bunny in inrange[i]
                lookat!(wolf, bunny)
                moveforward!(wolf, 1.1)
                dist = distance(wolf, bunny)
                if dist < 5.0
                    delete!(scene, bunny)
                end
                return
            end
        end
    end

    # Look into a random direction
    #setdirection!(wolf, normalize(rand(Float64,2).*2 .- 1))
    #moveforward!(wolf, 1)
end

function testgame()

    env = GameEnvironment(300,300)
    scene = Scene(env,[Plant,Bunny,Wolf])
    context = RenderingContext(300,300)

    for i in 1:30
        plant = Plant((rand(Float64,2).*300)...,true)
        push!(scene,plant)
    end

    for i in 1:30
        bunny = Bunny((rand(Float64,2).*300)...)
        push!(scene,bunny)
    end

    for i in 1:5
        wolf = Wolf((rand(Float64,2).*300)...,1,0)
        push!(scene,wolf)
    end

    while NxDraw2.tick() != 0
        step!(scene)
        render(scene,context)
    end
end

testgame()