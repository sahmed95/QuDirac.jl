warn("This example requires the Plotly package. See here for more: https://plot.ly/julia/getting-started/")

using QuDirac

#################################
# Hermite Polynomial Evaluation #
#################################
# This is a very naive implementation, 
# likely prone to numerical error and slowness 
# for high n. It should suffice for this example, 
# however. Implements the expression found here: 
# http://en.wikipedia.org/wiki/Hermite_polynomials#Recursion_relation
function hermite(n, x)
    if n == 0
        return 1
    elseif n == 1
        return 2 * x
    else
        return 2x*hermite(n-1, x) - 2*(n-1)*hermite(n-2, x)
    end
end 

##################
# QHOInner Setup #
##################
# Custom inner product type
# the QHO problem
@definner QHOInner

immutable PosX{T}
    pos::T
end

QHOInner(x::PosX, k::BigInt) = e^((-x.pos^2)/2) * hermite(k, x.pos) * 1/√(2^k * factorial(k) * √π) # using natural units
QHOInner(x::PosX, k::Int) = QHOInner(x, BigInt(k))
QHOInner(n::Int, m::Int) = KronDelta(n, m)

default_inner(QHOInner)

# With the above, we've defined this behavior for basis states:
# < i::Int | j::Int > = ∫ ψᵢ'ψⱼ dx =  δᵢⱼ
# < x::PosX | i::Int > = ψᵢ(x)

####################
# Ladder Operators #
####################
#
# `a` and `a_dag` are defined as the lowering and raising operators
# on individual states. `X` and `P` are defined as the position 
# and momentum operators on individual states.
#
# See the "Constructing Operators with Functions" section 
# of the QuDirac docs for more info on the use of the `@defop`
# macro. 
#
# Note that in practice, it is generally faster to use QuDirac's 
# built-in `lower` and `raise` functions to apply ladder operations
# to states. The following simply serves to demonstrate the capabilities
# of the `@defop` macro.

@defop "a | n > = √n * | n - 1 >"
@defop "< n | a = √(n + 1) * < n + 1 |"

# `X` and `P` are Hermitian, so:
@defop "X | n > = √(1/2) * (a * | n > +  a' * | n >)"
@defop "< n | X = √(1/2) * (< n | * a +  < n | * a')"

@defop "P | n > = im * √(1/2) * (a' * | n > - a * | n >)"
@defop "< n | P = im * √(1/2) * (< n | * a' - < n | * a)"

####################
# Make Some Plots! #
####################
# Here we're going to make some plots 
# with Plotly. You'll have to have an 
# account to do this, but it's free and
# totally awesome.

# Given an iterable of x and y points, generate a
# distribution for the state by taking the inner product
gen_z(kt::Ket, x, y) = [d" < i, j | * kt " for i in x, j in y]

# Generate the distribution above, and package it for a Plotly surface plot
function gen_plot_data{P}(kt::Ket{P,2}, x, y)
    return [
      [
        "z" => gen_z(kt, x, y),
        "x" => x, 
        "y" => y, 
        "type" => "surface"
      ]
    ]
end

# some default stuff
len = 50
max = pi
const xpoints = map(PosX,linspace(-max, max, len))

info("Loading the Plotly package, this could take a little while since it has to sign in...")

using Plotly

# Generate the distribution, sending it to Plotly.
# Return the response URL, which you can then go to
# to see and interact with your plot.
#
# To generate a plot of a wave function for a 2-factor Ket, 
# just call plot_wave2D(kt, xpoints, ypoints). This function
# will build your plot and return the URL you should go to to
# view the result. Here are some examples: 
#
# Basis state:
# julia> plot_wave2D(d" | 1, 1 > ")
#
# Random superposition of the first 4 basis states:
# julia> randkt = normalize!(sum(i -> rand() * ket(i), 0:3))^2
#        plot_wave2D(randkt)
#
function plot_wave2D{P}(kt::Ket{P,2})
    response = Plotly.plot(gen_plot_data(kt, xpoints, xpoints))
    return response["url"]
end

info("Finished loading Plotly. Make sure you're signed in before trying to plot!")
