using Mamba
using Distributions

## Data
seeds = (Symbol => Any)[
  :r => [10, 23, 23, 26, 17, 5, 53, 55, 32, 46, 10, 8, 10, 8, 23, 0, 3, 22, 15,
         32, 3],
  :n => [39, 62, 81, 51, 39, 6, 74, 72, 51, 79, 13, 16, 30, 28, 45, 4, 12, 41,
         30, 51, 7],
  :x1 => [0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1],
  :x2 => [0, 0, 0, 0, 0, 1, 1, 1, 1, 1, 1, 0, 0, 0, 0, 0, 1, 1, 1, 1, 1]
]
seeds[:N] = length(seeds[:r])


## Model Specification

model = MCMCModel(

  r = MCMCStochastic(1,
    @modelexpr(alpha0, alpha1, x1, alpha2, x2, alpha12, b, n, N,
      Distribution[
        begin
          p = invlogit(alpha0 + alpha1 * x1[i] + alpha2 * x2[i] +
                       alpha12 * x1[i] * x2[i] + b[i])
          Binomial(n[i], p)
        end
        for i in 1:N
      ]
    ),
    false
  ),

  b = MCMCStochastic(1,
    @modelexpr(s2,
      Normal(0, sqrt(s2))
    ),
    false
  ),

  alpha0 = MCMCStochastic(
    :(Normal(0, 1000))
  ),

  alpha1 = MCMCStochastic(
    :(Normal(0, 1000))
  ),

  alpha2 = MCMCStochastic(
    :(Normal(0, 1000))
  ),

  alpha12 = MCMCStochastic(
    :(Normal(0, 1000))
  ),

  s2 = MCMCStochastic(
    :(InverseGamma(0.001, 0.001))
  )

)


## Initial Values
inits = [
  [:r => seeds[:r], :alpha0 => 0, :alpha1 => 0, :alpha2 => 0,
   :alpha12 => 0, :s2 => 0.01, :b => zeros(seeds[:N])],
  [:r => seeds[:r], :alpha0 => 0, :alpha1 => 0, :alpha2 => 0,
   :alpha12 => 0, :s2 => 1, :b => zeros(seeds[:N])]
]


## Sampling Scheme
scheme = [AMM([:alpha0, :alpha1, :alpha2, :alpha12], 0.01 * eye(4)),
          AMWG([:b], fill(0.01, seeds[:N])),
          Slice([:s2], [1.0])]
setsamplers!(model, scheme)


## MCMC Simulations
sim = mcmc(model, seeds, inits, 10000, burnin=2500, thin=2, chains=2)
describe(sim)
