@testset "bool -> Bool" begin
    @test pyconvert(Bool, true) === true
    @test pyconvert(Bool, false) === false
    @test_throws Exception pyconvert(Bool, "hello")
end

@testset "bool -> Integer" begin
    @test pyconvert(Int, true) === 1
    @test pyconvert(Int, false) === 0
end

@testset "bytes -> Vector" begin
    x1 = pyconvert(Vector{UInt8}, pybytes(pylist([1, 2, 3])))
    @test x1 isa Vector{UInt8}
    @test x1 == [0x01, 0x02, 0x03]
    x2 = pyconvert(Base.CodeUnits, pybytes(pylist([102, 111, 111])))
    @test x2 isa Base.CodeUnits
    @test x2 == b"foo"
end

@testset "complex -> Complex" begin
    x1 = pyconvert(ComplexF32, pycomplex(1, 2))
    @test x1 === ComplexF32(1, 2)
    x2 = pyconvert(Complex, pycomplex(3, 4))
    @test x2 === ComplexF64(3, 4)
end

@testset "float -> Float" begin
    x1 = pyconvert(Float32, 12)
    @test x1 === Float32(12)
    x2 = pyconvert(Float64, 3.5)
    @test x2 === 3.5
end

@testset "float -> Nothing" begin
    @test_throws Exception pyconvert(Nothing, pyfloat(1.2))
    x1 = pyconvert(Nothing, pyfloat(NaN))
    @test x1 === nothing
end

@testset "float -> Missing" begin
    @test_throws Exception pyconvert(Missing, pyfloat(1.2))
    x1 = pyconvert(Missing, pyfloat(NaN))
    @test x1 === missing
end

@testset "int -> Integer" begin
    @test_throws Exception pyconvert(Int8, 300)
    @test_throws Exception pyconvert(UInt, -3)
    x1 = pyconvert(Int, 34)
    @test x1 === 34
    x2 = pyconvert(UInt8, 7)
    @test x2 === 0x07
    x3 = pyconvert(UInt32, typemax(UInt32))
    @test x3 === typemax(UInt32)
    x4 = pyconvert(Integer, big(3)^1000)
    @test x4 isa BigInt
    @test x4 == big(3)^1000
end

@testset "None -> Nothing" begin
    x1 = pyconvert(Nothing, pybuiltins.None)
    @test x1 === nothing
end

@testset "None -> Missing" begin
    x1 = pyconvert(Missing, pybuiltins.None)
    @test x1 === missing
end

@testset "range -> StepRange" begin
    x1 = pyconvert(StepRange, pyrange(10))
    @test x1 === (0:1:9)
    x2 = pyconvert(StepRange, pyrange(3, 9, 2))
    @test x2 === (3:2:7)
    x3 = pyconvert(StepRange, pyrange(20, 14, -1))
    @test x3 === (20:-1:15)
    x4 = pyconvert(StepRange, pyrange(30, -10, -3))
    @test x4 === (30:-3:-9)
end

@testset "range -> UnitRange" begin
    x1 = pyconvert(UnitRange, pyrange(10))
    @test x1 === (0:9)
    x2 = pyconvert(UnitRange, pyrange(3, 9, 1))
    @test x2 === (3:8)
end

@testset "str -> String" begin
    x1 = pyconvert(String, pystr("foo"))
    @test x1 === "foo"
    x2 = pyconvert(String, pystr("αβγℵ√"))
    @test x2 === "αβγℵ√"
end

@testset "str -> Symbol" begin
    x1 = pyconvert(Symbol, pystr("hello"))
    @test x1 === :hello
end

@testset "str -> Char" begin
    @test_throws Exception pyconvert(Char, pystr(""))
    @test_throws Exception pyconvert(Char, pystr("ab"))
    @test_throws Exception pyconvert(Char, pystr("abc"))
    x1 = pyconvert(Char, pystr("a"))
    @test x1 === 'a'
    x2 = pyconvert(Char, pystr("Ψ"))
    @test x2 === 'Ψ'
end

@testset "iterable -> Tuple" begin
    t1 = pyconvert(Tuple, (1, 2))
    @test t1 === (1, 2)
    t2 = pyconvert(Tuple{Vararg{Int}}, (3, 4, 5))
    @test t2 === (3, 4, 5)
    t3 = pyconvert(Tuple{Int,Int}, (6, 7))
    @test t3 === (6, 7)
    # generic case (>16 fields)
    t4 = pyconvert(Tuple{ntuple(i->Int,20)...,Vararg{Int}}, ntuple(i->i, 30))
    @test t4 === ntuple(i->i, 30)
end

@testset "iterable -> Vector" begin
    x1 = pyconvert(Vector, pylist([1, 2]))
    @test x1 isa Vector{Int}
    @test x1 == [1, 2]
    x2 = pyconvert(Vector, pylist([1, 2, nothing, 3]))
    @test x2 isa Vector{Union{Int,Nothing}}
    @test x2 == [1, 2, nothing, 3]
    x3 = pyconvert(Vector{Float64}, pylist([4, 5, 6]))
    @test x3 isa Vector{Float64}
    @test x3 == [4.0, 5.0, 6.0]
end

@testset "iterable -> Set" begin
    x1 = pyconvert(Set, pyset([1, 2]))
    @test x1 isa Set{Int}
    @test x1 == Set([1, 2])
    x2 = pyconvert(Set, pyset([1, 2, nothing, 3]))
    @test x2 isa Set{Union{Int,Nothing}}
    @test x2 == Set([1, 2, nothing, 3])
    x3 = pyconvert(Set{Float64}, pyset([4, 5, 6]))
    @test x3 isa Set{Float64}
    @test x3 == Set([4.0, 5.0, 6.0])
end

@testset "iterable -> Pair" begin
    @test_throws Exception pyconvert(Pair, ())
    @test_throws Exception pyconvert(Pair, (1,))
    @test_throws Exception pyconvert(Pair, (1, 2, 3))
    x1 = pyconvert(Pair, (2, 3))
    @test x1 === (2 => 3)
    x2 = pyconvert(Pair{String,Missing}, ("foo", nothing))
    @test x2 === ("foo" => missing)
end

@testset "mapping -> Dict" begin
    x1 = pyconvert(Dict, pydict(["a"=>1, "b"=>2]))
    @test x1 isa Dict{String, Int}
    @test x1 == Dict("a"=>1, "b"=>2)
    x2 = pyconvert(Dict{Char,Float32}, pydict(["c"=>3, "d"=>4]))
    @test x2 isa Dict{Char,Float32}
    @test x2 == Dict('c'=>3.0, 'd'=>4.0)
end

@testset "date -> Date" begin
    x1 = pyconvert(Date, pydate(2001, 2, 3))
    @test x1 === Date(2001, 2, 3)
end

@testset "time -> Time" begin
    x1 = pyconvert(Time, pytime(12, 3, 4, 5))
    @test x1 === Time(12, 3, 4, 0, 5)
end

@testset "datetime -> DateTime" begin
    x1 = pyconvert(DateTime, pydatetime(2001, 2, 3, 4, 5, 6, 7000))
    @test x1 === DateTime(2001, 2, 3, 4, 5, 6, 7)
end
