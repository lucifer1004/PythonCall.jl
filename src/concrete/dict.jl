pydict_setitem(x::PyRef, k, v) = errcheck(@autopy k v C.PyDict_SetItem(getptr(x), getptr(k_), getptr(v_)))

function pydict_fromiter!(ans::PyRef, kvs)
    d_, k_, v_ = pytuplerefs!(ans, Val(3))
    pydict!(d_)
    for (k, v) in kvs
        Py!(k_, k)
        Py!(v_, v)
        pydict_setitem(d_, k_, v_)
    end
    Py!(ans, d_)
    return ans
end

pydict_fromiter(kvs) = pydict_fromiter!(pynew(), kvs)

function pystrdict_fromiter!(ans::PyRef, kvs)
    d_, k_, v_ = pytuplerefs!(ans, Val(3))
    pydict!(d_)
    for (k, v) in kvs
        Py!(k_, string(k))
        Py!(v_, v)
        pydict_setitem(d_, k_, v_)
    end
    Py!(ans, d_)
    return ans
end

pystrdict_fromiter(kvs) = pystrdict_fromiter!(pynew(), kvs)

pydict!(ans::PyRef; kwargs...) = isempty(kwargs) ? setptr!(ans, errcheck(C.PyDict_New())) : pystrdict_fromiter!(ans, kwargs)
pydict!(ans::PyRef, x) = ispy(x) ? pycall!(ans, pybuiltins.dict, x) : pydict_fromiter!(ans, x)
pydict!(ans::PyRef, x::NamedTuple) = pydict!(ans; x...)

"""
    pydict(x)
    pydict(; x...)

Convert `x` to a Python `dict`. In the second form, the keys are strings.

If `x` is a Python object, this is equivalent to `dict(x)` in Python.
Otherwise `x` must iterate over key-value pairs.
"""
pydict(; kwargs...) = pydict!(pynew(); kwargs...)
pydict(x) = pydict!(pynew(), x)
export pydict
