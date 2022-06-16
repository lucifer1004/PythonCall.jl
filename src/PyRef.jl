"""
    abstract type PyRef

A `PyRef` is a Julia object containing a mutable reference to a Python object.

Subtypes must support: `getptr(::T)` and `setptr!(::T, ptr::C.PyPtr)`.

`Py` and `PyTupleRef` are examples.
"""
abstract type PyRef end

ispy(::PyRef) = true


### PyNullRef

struct PyNullRef <: PyRef end


### PyTupleRef

struct PyTupleRef <: PyRef
    ptr::C.PyPtr
    idx::C.Py_ssize_t
end

getptr(x::PyTupleRef) = C.PyTuple_GetItem(x.ptr, x.idx)
setptr!(x::PyTupleRef, ptr::C.PyPtr) = (errcheck(C.PyTuple_SetItem(x.ptr, x.idx, ptr)); x)

function pytuplerefs!(ans::PyRef, ::Val{N}) where {N}
    pynulltuple!(ans, N)
    ptr = getptr(ans)
    return ntuple(i->PyTupleRef(ptr, i-1), Val(N))
end

function pyargref!(ans::PyRef, a)
    if ispy(a)
        return a
    else
        Py!(ans, a)
        return ans
    end
end

function pyargrefs!(ans::PyRef, a)
    return (pyargref!(ans, a),)
end

function pyargrefs!(ans::PyRef, a, b)
    if ispy(a) && ispy(b)
        return (a, b)
    else
        (ar, br) = pytuplerefs!(ans, Val(2))
        Py!(ar, a)
        Py!(br, b)
        return (ar, br)
    end
end

function pyargrefs!(ans::PyRef, a, b, c)
    if ispy(a) && ispy(b) && ispy(c)
        return (a, b, c)
    else
        (ar, br, cr) = pytuplerefs!(ans, Val(3))
        Py!(ar, a)
        Py!(br, b)
        Py!(cr, c)
        return (ar, br, cr)
    end
end


### PyListRef

struct PyListRef <: PyRef
    ptr::C.PyPtr
    idx::C.Py_ssize_t
end

getptr(x::PyListRef) = C.PyList_GetItem(x.ptr, x.idx)
setptr!(x::PyListRef, ptr::C.PyPtr) = (errcheck(C.PyList_SetItem(x.ptr, x.idx, ptr)); x)
