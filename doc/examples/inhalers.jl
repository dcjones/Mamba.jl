using Mamba
using Distributions

## Data
inhalers = (Symbol => Any)[
  :pattern =>
    [1 1 1 1 2 2 2 2 3 3 3 3 4 4 4 4
     1 2 3 4 1 2 3 4 1 2 3 4 1 2 3 4]',
  :Ncum =>
    [ 59 157 173 175 186 253 270 271 271 278 280 281 282 285 285 286
     122 170 173 175 226 268 270 271 278 280 281 281 284 285 286 286]',
  :treat =>
    [ 1 -1
     -1  1],
  :period =>
    [1 -1
     1 -1],
  :carry =>
    [0 -1
     0  1],
  :N => 286,
  :T => 2,
  :G => 2,
  :Npattern => 16,
  :Ncut => 3
]

inhalers[:group] = Array(Int, inhalers[:N])
inhalers[:response] = Array(Int, inhalers[:N], inhalers[:T])

i = 1
for k in 1:inhalers[:Npattern], g in 1:inhalers[:G]
  while i <= inhalers[:Ncum][k,g]
    inhalers[:group][i] = g
    for t in 1:inhalers[:T]
      inhalers[:response][i,t] = inhalers[:pattern][k,t]
    end
    i += 1
  end
end


## Model Specification

model = MCMCModel(

  response = MCMCStochastic(2,
    @modelexpr(a1, a2, a3, mu, group, b, N, T,
      begin
        a = Float64[a1, a2, a3]
        Distribution[
          begin
            eta = mu[group[i],t] + b[i]
            p = ones(4)
            for j in 1:3
              Q = invlogit(-(a[j] + eta))
              p[j] -= Q
              p[j+1] = Q
            end
            Categorical(p)
          end
          for i in 1:N, t in 1:T
        ]
      end
    ),
    false
  ),

  mu = MCMCLogical(2,
    @modelexpr(beta, treat, pi, period, kappa, carry, G, T,
      [ beta * treat[g,t] / 2 + pi * period[g,t] / 2 + kappa * carry[g,t]
        for g in 1:G, t in 1:T ]
    ),
    false
  ),

  b = MCMCStochastic(1,
    @modelexpr(s2,
      Normal(0, sqrt(s2))
    ),
    false
  ),

  a1 = MCMCStochastic(
    @modelexpr(a2,
      Truncated(Flat(), -1000, a2)
    )
  ),

  a2 = MCMCStochastic(
    @modelexpr(a3,
      Truncated(Flat(), -1000, a3)
    )
  ),

  a3 = MCMCStochastic(
    :(Truncated(Flat(), -1000, 1000))
  ),

  beta = MCMCStochastic(
    :(Normal(0, 1000))
  ),

  pi = MCMCStochastic(
    :(Normal(0, 1000))
  ),

  kappa = MCMCStochastic(
    :(Normal(0, 1000))
  ),

  s2 = MCMCStochastic(
    :(InverseGamma(0.001, 0.001))
  )

)


## Initial Values
inits = [
  [:response => inhalers[:response], :beta => 0, :pi => 0, :kappa => 0,
   :a1 => 2, :a2 => 3, :a3 => 4, :s2 => 1, :b => zeros(inhalers[:N])],
  [:response => inhalers[:response], :beta => 1, :pi => 1, :kappa => 0,
   :a1 => 3, :a2 => 4, :a3 => 5, :s2 => 10, :b => zeros(inhalers[:N])]
]


## Sampling Scheme
scheme = [AMWG([:b], fill(0.1, inhalers[:N])),
          Slice([:a1, :a2, :a3], fill(2.0, 3)),
          SliceWG([:beta, :pi, :kappa, :s2], fill(1.0, 4))]
setsamplers!(model, scheme)


## MCMC Simulations
sim = mcmc(model, inhalers, inits, 5000, burnin=1000, thin=2, chains=2)
describe(sim)
