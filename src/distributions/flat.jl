#################### Flat Distribution ####################

type Flat <: ContinuousUnivariateDistribution end

minimum(d::Flat) = -Inf
maximum(d::Flat) = Inf
insupport(d::Flat, x::Real) = true

logpdf(d::Flat, x::Real) = 0.0

function Truncated(d::Flat, l::Real, u::Real)
  Truncated{Flat,Continuous}(d, l, u, 1.0)
end
