
using LinearAlgebra

abstract type AbstractEntity end

abstract type AbstractEnvironment end

abstract type AbstractEuclideanEnvironment <: AbstractEnvironment end

abstract type Abstract2DEnvironment <: AbstractEuclideanEnvironment end

struct Scene{T<:Tuple,E<:AbstractEnvironment}
    environment::E
    entities::T
end

function Scene(env::E,types::Vector{DataType}) where {E<:AbstractEnvironment}
    Scene(env,Tuple([Vector{type}() for type in types]))
end

function step!(scene::Scene)
    for entityvec in scene.entities
        for entity in entityvec
            step!(entity,scene)
        end
    end
end

@generated function indexof(::Scene{EntityVectors}, entity::E) where
                                         {EntityVectors, E <: AbstractEntity}
    index = 0
    for i in 1:length(EntityVectors.types)
        if EntityVectors.types[i] == Vector{E}
            index = i
        end
    end
    if index == 0
        error("No vector of type $(E) in Scene of type Scene{$EntityVectors}")
    end
    quote
        $index
    end
end

function Base.push!(scene::Scene, entity::T) where {T <: AbstractEntity}
    Base.push!(scene.entities[indexof(scene, entity)], entity)
end

function delete!(scene::Scene, entity::T) where {T <: AbstractEntity}
    entitiesvec = scene.entities[indexof(scene, entity)]
    
    deleteat!(entitiesvec, findfirst(x->x==entity,entitiesvec))
end

abstract type AbstractPositionEntity <: AbstractEntity end

distance(a::T, b::S) where {T <: AbstractPositionEntity, 
                            S <: AbstractPositionEntity} = 
                                        norm(getposition(b) .- getposition(a))

function inrange(scene::Scene{W,E}, entity::T, range::N)::W where 
    {E,T <: AbstractPositionEntity, W <: Tuple, N <: Number}

    types = W.types
    result = [ type() for type in types ]

    for (i,entityvec) in enumerate(scene.entities)
        othertype = eltype(entityvec)
        if othertype <: AbstractPositionEntity
            for other in entityvec
                d = distance(entity, other)
                if d < range
                    push!(result[i], other)
                end
            end
        end
    end

    return Tuple(result)
end

function inrangesorted(scene::Scene{W,E}, entity::T, range::N)::W where 
                    {E,T <: AbstractPositionEntity, W <: Tuple, N <: Number}

    types = W.types
    result = [ Vector{Tuple{eltype(type),N}}() for type in types ]

    for (i,entityvec) in enumerate(scene.entities)
        othertype = eltype(entityvec)
        if othertype <: AbstractPositionEntity
            for other in entityvec
                d = distance(entity, other)
                if d < range
                    push!(result[i], (other,d))
                end
            end
        end
        sort!(result[i], by=x->x[2])
    end

    result = [ type([ elem[1] for elem in result[i] ]) for 
                                            (i,type) in enumerate(types) ]

    return Tuple(result)
end

abstract type AbstractDirectionalEntity <: AbstractPositionEntity end

function moveforward!(entity::T, speed::N) where 
                        {T <: AbstractDirectionalEntity, N <: Number} 

    setposition!(entity,getposition(entity) + speed * getdirection(entity))
end

function lookat!(entity::T, target::V) where 
                        {T <: AbstractDirectionalEntity, V <: AbstractVector}
    setdirection!(entity,normalize(target - getposition(entity)))
end

function lookaway!(entity::T, target::V) where 
                        {T <: AbstractDirectionalEntity, V <: AbstractVector}
    setdirection!(entity,normalize(getposition(entity) - target))
end

function lookat!(entity::T, target::O) where 
                {T <: AbstractDirectionalEntity, O <: AbstractPositionEntity}
    lookat!(entity, getposition(target))
end
    
function lookaway!(entity::T, target::O) where 
                {T <: AbstractDirectionalEntity, O <: AbstractPositionEntity}
    lookaway!(entity, getposition(target))
end

