# change this if you don't want to use Gurobi
m = Model(solver=GurobiSolver(Presolve=0, OutputFlag=0))

# objective 1: maximize 2*a + 7*b
# objective 2: minimize 3*a - 2*b
# whichever objective that isn't enabled will be shown
#   on the slider

@variable(m, a >= 0)
@variable(m, b >= 0)
@constraint(m, a + 4*b <= 75)
@constraint(m, a <= 20)
@constraint(m, b >= 13)

a1 = AffExpr([a, b], [2, 7], 0)
a2 = AffExpr([a, b], [3, -2], 0)

# Three sliders will appear: one to shift the vertical
#  line on the plot, one to change which objective to
#  use, and one to control printing of the optimal
#  solution.
plotTwoCriteriaOpt(m, a1, a2, :Max, :Min)

# This is one of the visualization examples shown on
#  this MATLAB website:
#  https://www.mathworks.com/help/symbolic/mupad_ref/linopt-plot_data.html
m = Model(solver=GurobiSolver())
@variable(m, x)
@variable(m, y)
@constraint(m, 2*x + 2*y - 4 >= 0)
@constraint(m, 4*y - 2*x + 2 >= 0)
@constraint(m, -2*x + y + 8 >= 0)
@constraint(m, 2*x - y - 2 >= 0)
@objective(m, Min, x + y)

plotGivenModel(m)