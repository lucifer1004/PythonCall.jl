# :PyComplex_FromDoubles => (Cdouble, Cdouble) => PyPtr,
# :PyComplex_RealAsDouble => (PyPtr,) => Cdouble,
# :PyComplex_ImagAsDouble => (PyPtr,) => Cdouble,
# :PyComplex_AsCComplex => (PyPtr,) => Py_complex,

pycomplex!(ans::PyRef, x::Real=0.0, y::Real=0.0) = setptr!(ans, errcheck(C.PyComplex_FromDoubles(x, y)))
pycomplex!(ans::PyRef, x::Complex) = pycomplex!(ans, real(x), imag(x))
pycomplex!(ans::PyRef, x, y) = pycall!(ans, pybuiltins.complex, x, y)
pycomplex!(ans::PyRef, x) = pycall!(ans, pybuiltins.complex, x)

"""
    pycomplex(x=0.0)
    pycomplex(re, im)

Convert `x` to a Python `complex`, or create one from given real and imaginary parts.
"""
pycomplex(x, y) = pycomplex!(pynew(), x, y)
pycomplex(x=0.0) = pycomplex!(pynew(), x)
pycomplex(x::Real) = pycomplex!(pynew(), x, 0.0)
export pycomplex

pyiscomplex(x) = pytypecheck(x, pybuiltins.complex)

function pycomplex_ascomplex(x)
    c = @autopy x C.PyComplex_AsCComplex(getptr(x_))
    c.real == -1 && c.imag == 0 && errcheck()
    return Complex(c.real, c.imag)
end

function pyconvert_rule_complex(::Type{T}, x::Py) where {T<:Number}
    val = pycomplex_ascomplex(x)
    if T in (Complex{Float64}, Complex{Float32}, Complex{Float16}, Complex{BigFloat})
        pyconvert_return(T(val))
    else
        pyconvert_tryconvert(T, val)
    end
end
