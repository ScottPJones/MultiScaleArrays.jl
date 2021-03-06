level_iter(S, n::Int) = n == 1 ? S.nodes : chain((level_iter(node, n-1) for node in S.nodes)...)

struct LevelIterIdx{T}
    iter::T
end
LevelIterIdx(S::AbstractMultiScaleArray, n::Int) = LevelIterIdx(level_iter(S, n))

Base.start(l::LevelIterIdx) = (start(l.iter), 1)
function Base.next(l::LevelIterIdx, state)
    val, new_state = next(l.iter, state[1])
    end_idx = state[2] + length(val) - 1
    ((val, state[2], end_idx), (new_state, end_idx + 1))
end
Base.done(l::LevelIterIdx, state) = done(l.iter, state[1])
