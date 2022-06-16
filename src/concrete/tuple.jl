pynulltuple!(ans::PyRef, len) = setptr!(ans, errcheck(C.PyTuple_New(len)))

pynulltuple(len) = pynulltuple!(pynew(), len)

function pytuple_setitem(xs::PyRef, i, x)
    Py!(PyTupleRef(getptr(xs), i), x)
    # errcheck(C.PyTuple_SetItem(getptr(xs), i, incref(getptr(Py(x)))))
    return xs
end

function pytuple_getitem!(ans::PyRef, xs::Py, i)
    GC.@preserve xs setptr!(ans, incref(errcheck(C.PyTuple_GetItem(getptr(xs), i))))
end

pytuple_getitem(xs, i) = pytuple_getitem!(pynew(), xs, i)

function pytuple_fromiter!(ans::PyRef, xs)
    sz = Base.IteratorSize(typeof(xs))
    if sz isa Base.HasLength || sz isa Base.HasShape
        # length known, e.g. Tuple, Pair, Vector
        pynulltuple!(ans, length(xs))
        for (i, x) in enumerate(xs)
            pytuple_setitem(ans, i-1, x)
        end
    else
        # length unknown
        pylist_fromiter!(ans, xs)
        pylist_astuple!(ans, ans)
    end
    return ans
end

@generated function pytuple_fromiter!(ans::PyRef, xs::Tuple)
    n = length(xs.parameters)
    code = []
    push!(code, :(pynulltuple!(ans, $n)))
    for i in 1:n
        push!(code, :(pytuple_setitem(ans, $(i-1), xs[$i])))
    end
    push!(code, :(return ans))
    return Expr(:block, code...)
end

pytuple_fromiter(xs) = pytuple_fromiter!(pynew(), xs)

pytuple!(ans::PyRef) = pynulltuple!(ans, 0)
pytuple!(ans::PyRef, x) = ispy(x) ? pycall!(ans, pybuiltins.tuple, x) : pytuple_fromiter!(ans, x)

"""
    pytuple([x])

Convert `x` to a Python `tuple`.

If `x` is a Python object, this is equivalent to `tuple(x)` in Python.
Otherwise `x` must be iterable.
"""
pytuple() = pytuple!(pynew())
pytuple(x) = pytuple!(pynew(), x)
export pytuple

pyistuple(x) = pytypecheckfast(x, C.Py_TPFLAGS_TUPLE_SUBCLASS)
