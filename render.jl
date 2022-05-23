using NxDraw2

include("sim.jl")

struct RenderingContext
    evbuff::Array{UInt8}
    screen::Array{UInt8}
    palette::Array{UInt8}
    width::Int32
    height::Int32
end

colors = [
    (0x00,0x00,0x00),(0x00,0x55,0x00),(0x00,0xAA,0x00),(0x00,0xFF,0x00),
    (0x00,0x00,0xFF),(0x00,0x55,0xFF),(0x00,0xAA,0xFF),(0x00,0xFF,0xFF),
    (0xFF,0x00,0x00),(0xFF,0x55,0x00),(0xFF,0xAA,0x00),(0xFF,0xFF,0x00),
    (0xFF,0x00,0xFF),(0xFF,0x55,0xFF),(0xFF,0xAA,0xFF),(0xFF,0xFF,0xFF)
]

function RenderingContext(width::Int64,height::Int64)
    
    palette_size = Int32(16)

    evbuf = Array{UInt8}(undef,2048)
    screen = Array{UInt8}(undef, NxDraw2.size_screen(Int32.((width,height))...))
    palette = Array{UInt8}(undef,NxDraw2.size_palette(palette_size))

    NxDraw2.init_event(evbuf)
    NxDraw2.init_window(UInt32.((width*2,height*2))...)
    NxDraw2.init_canvas(screen,UInt32.((width,height,4))...)
    NxDraw2.init_palette(palette,NxDraw2.size_palette(palette_size))

    for i in 0:15
        NxDraw2.palette_rgb(UInt32(i),colors[i+1]...)
    end

    return RenderingContext(evbuf,screen,palette,width,height)
end

function render(scene::Scene, context::RenderingContext)

    NxDraw2.palette_bg(UInt32(1))
    
    NxDraw2.draw_clear()

    for entityvec in scene.entities
        for entity in entityvec
            render(scene,entity,context)
        end
    end

    NxDraw2.present()
end

function colorof(::E)::UInt8 where {E <: AbstractEntity}
    (hash(E) % 8) + 7
end

function render(::Scene,::AbstractEntity,::RenderingContext)
end

function renderbase(scene::Scene{S,E}, entity::T, 
                                context::RenderingContext) where 
    {S, T <: AbstractPositionEntity, E <: Abstract2DEnvironment} 

    NxDraw2.palette_fg(UInt32(colorof(entity)))

    normpos = getposition(entity) ./ getsize(scene.environment)

    #println(getposition(entity))

    post = floor.(normpos .* getsize(scene.environment))

    rsize = 3

    NxDraw2.draw_rectangle(Int32.(((post .- rsize .÷ 2)...,rsize,rsize))...)
end

function render(scene::Scene{S,E}, entity::T, context::RenderingContext) where 
        {S<:Tuple, T <: AbstractPositionEntity, E <: Abstract2DEnvironment} 

    renderbase(scene,entity,context)
end

function render(scene::Scene{S,E}, entity::T, context::RenderingContext) where 
        {S<:Tuple, T <: AbstractDirectionalEntity, E <: Abstract2DEnvironment} 

    renderbase(scene,entity,context)

    normpos = getposition(entity) ./ getsize(scene.environment)

    post = floor.(normpos .* getsize(scene.environment))

    target = floor.(post .+ getdirection(entity).*3)

    NxDraw2.draw_line(Int32.((post...,target...))...)
end