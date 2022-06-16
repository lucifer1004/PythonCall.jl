pynulllist!(ans::PyRef, len) = setptr!(ans, errcheck(C.PyList_New(len)))

pynulllist(len) = pynulllist!(pynew(), len)

function pylist_setitem(xs::Py, i, x)
    Py!(PyListRef(getptr(xs), i), x)
    # errcheck(C.PyList_SetItem(getptr(xs), i, incref(getptr(Py(x)))))
    return xs
end

pylist_append(xs::Py, x) = errcheck(@autopy x C.PyList_Append(getptr(xs), getptr(x_)))

pylist_astuple!(ans::PyRef, x) = setptr!(ans, errcheck(@autopy x C.PyList_AsTuple(getptr(x_))))

pylist_astuple(x) = pylist_astuple!(pynew(), x)

function pylist_fromiter!(ans::PyRef, xs)
    sz = Base.IteratorSize(typeof(xs))
    if sz isa Base.HasLength || sz isa Base.HasShape
        # length known
        pynulllist!(ans, length(xs))
        for (i, x) in enumerate(xs)
            pylist_setitem(ans, i-1, x)
        end
    else
        # length unknown
        pynulllist!(ans, 0)
        for (i, x) in enumerate(xs)
            # pylist_append(ans, x) allocates
            pylist_append(ans, nothing)
            pylist_setitem(ans, i-1, x)
        end
    end
    return ans
end

pylist_fromiter(xs) = pylist_fromiter!(pynew(), xs)

pylist!(ans::PyRef) = pynulllist!(ans, 0)
pylist!(ans::PyRef, x) = ispy(x) ? pycall!(ans, pybuiltins.list, x) : pylist_fromiter!(ans, x)

"""
    pylist([x])

Convert `x` to a Python `list`.

If `x` is a Python object, this is equivalent to `list(x)` in Python.
Otherwise `x` must be iterable.
"""
pylist() = pylist!(pynew())
pylist(x) = pylist!(pynew(), x)
export pylist

"""
    pycollist(x::AbstractArray)

Create a nested Python `list`-of-`list`s from the elements of `x`. For matrices, this is a list of columns.
"""
function pycollist(x::AbstractArray{T,N}) where {T,N}
    N == 0 && return pynew(Py(x[]))
    d = N
    ax = axes(x, d)
    ans = pynulllist(length(ax))
    for (i, j) in enumerate(ax)
        y = pycollist(selectdim(x, d, j))
        pylist_setitem(ans, i-1, y)
        pydel!(y)
    end
    return ans
end
export pycollist

"""
    pyrowlist(x::AbstractArray)

Create a nested Python `list`-of-`list`s from the elements of `x`. For matrices, this is a list of rows.
"""
function pyrowlist(x::AbstractArray{T,N}) where {T,N}
    ndims(x) == 0 && return pynew(Py(x[]))
    d = 1
    ax = axes(x, d)
    ans = pynulllist(length(ax))
    for (i, j) in enumerate(ax)
        y = pyrowlist(selectdim(x, d, j))
        pylist_setitem(ans, i-1, y)
        pydel!(y)
    end
    return ans
end
export pyrowlist
