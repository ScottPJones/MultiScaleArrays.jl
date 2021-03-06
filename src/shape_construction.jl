length(m::AbstractMultiScaleArrayLeaf) = length(m.values)
length(m::AbstractMultiScaleArray) = m.end_idxs[end]
num_nodes(m::AbstractMultiScaleArrayLeaf) = 0
num_nodes(m::AbstractMultiScaleArray) = size(m.nodes, 1)
ndims(m::AbstractMultiScaleArray) = 1
size(m::AbstractMultiScaleArray, i::Int) = i == 1 ? length(m) : 0
size(m::AbstractMultiScaleArray) = (length(m),)

parameterless_type(T::Type) = Base.typename(T).wrapper
parameterless_type(x) = parameterless_type(typeof(x))

@generated function similar(m::AbstractMultiScaleArrayLeaf,::Type{T}=eltype(m)) where T
    assignments = [s == :x ? :(similar(m.x, T)) :
                   (sq = Meta.quot(s); :(deepcopy(getfield(m, $sq))))
                   for s in fieldnames(m)[2:end]] # 1 is values
    :(construct(parameterless_type(m), similar(m.values,T),$(assignments...)))
end

@generated function similar(m::AbstractMultiScaleArray,::Type{T}=eltype(m)) where {T}
    assignments = [s == :x ? :(similar(m.x, T, dims)) :
                   (sq = Meta.quot(s); :(deepcopy(getfield(m, $sq))))
                   for s in fieldnames(m)[4:end]] # 1:3 is nodes,values,end_idxs
    :(construct(parameterless_type(m), recursive_similar(m.nodes,T),similar(m.values, T),$(assignments...)))
end

recursive_similar(x,T) = [similar(y, T) for y in x]

construct(::Type{T}, args...) where {T<:AbstractMultiScaleArrayLeaf} = T(args...)

function __construct(nodes::Vector{<:AbstractMultiScaleArray})
    end_idxs = Vector{Int}(length(nodes))
    off = 0
    @inbounds for i in 1:length(nodes)
        end_idxs[i] = (off += length(nodes[i]))
    end
    end_idxs
end

function (construct(::Type{T}, nodes::Vector{<:AbstractMultiScaleArray},args...)
          where {T<:AbstractMultiScaleArray})
    T(nodes, eltype(T)[], __construct(nodes),args...)
end

function (construct(::Type{T}, nodes::Vector{<:AbstractMultiScaleArray}, values, args...)
          where {T<:AbstractMultiScaleArray})
    vallen = length(values)
    end_idxs = Vector{Int}(length(nodes) + ifelse(vallen == 0, 0, 1))
    off = 0
    @inbounds for i in 1:length(nodes)
        end_idxs[i] = (off += length(nodes[i]))
    end
    vallen == 0 || (end_idxs[end] = off + vallen)
    T(nodes, values, end_idxs, args...)
end

vcat(m1::AbstractMultiScaleArray, m2::AbstractMultiScaleArray) =
    error("AbstractMultiScaleArrays cannot be concatenated")

hcat(m1::AbstractMultiScaleArray, m2::AbstractMultiScaleArray) =
    error("AbstractMultiScaleArrays cannot be concatenated")

==(m1::AbstractMultiScaleArray, m2::AbstractMultiScaleArray) = (m1 === m2)

function recursivecopy!(b::AbstractMultiScaleArrayLeaf, a::AbstractMultiScaleArrayLeaf)
    @inbounds copy!(b,a)
end

function recursivecopy!(b::AbstractMultiScaleArray, a::AbstractMultiScaleArray)
    @inbounds for i in eachindex(a.nodes)
        recursivecopy!(b.nodes[i], a.nodes[i])
    end
    @inbounds for i in eachindex(a.values)
        recursivecopy!(b.values[i], a.values[i])
    end
end
