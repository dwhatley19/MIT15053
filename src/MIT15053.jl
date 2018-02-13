module MIT15053

using Interact, Reactive
using Gadfly
using Plots
using JuMP, Gurobi

export plotTwoCriteriaOpt

function plotTwoCriteriaOpt(base::Model, c1::AffExpr, c2::AffExpr, m1::Symbol, m2::Symbol,
        min=-20, max=50, hugenum=1e18)

    basecopy = deepcopy(base)
    c1copy = copy(c1,basecopy)
    c2copy = copy(c2,basecopy)

    @constraint(basecopy, c1less, c1copy <= hugenum)
    @constraint(basecopy, c1more, c1copy >= -hugenum)
    @constraint(basecopy, c2less, c2copy <= hugenum)
    @constraint(basecopy, c2more, c2copy >= -hugenum)

    # create cache so that not every optimization problem
    #   has to be solved every re-plot
    cache = Dict()
    function s(r, obj)
        if Base.haskey(cache, r)
            return Base.get(cache, r, (-1,-1,-1))
        end

        if obj == 1
            # objective 1 is objective, objective 2 is constraint
            @objective(basecopy, m1, c1copy)
            if m2 == :Min
                JuMP.setRHS(c2less, r)
            else
                JuMP.setRHS(c2more, r)
            end
        else
            # objective 2 is objective, objective 1 is constraint
            @objective(basecopy, m2, c2copy)
            if m1 == :Min
                JuMP.setRHS(c1less, r)
            else
                JuMP.setRHS(c1more, r)
            end
        end
        solve(basecopy, suppress_warnings=true)
        cache[r] = (getobjectivevalue(basecopy), getvalue(c1copy), getvalue(c2copy))
        return getobjectivevalue(basecopy), getvalue(c1copy), getvalue(c2copy)
    end

    # use the GR plot library
    gr()
    @manipulate for r in min:max, obj in 1:2, print in 0:1
        if print == 1
            println(s(r, obj)[2:3])
        end
        Plots.plot(x -> s(x, obj)[1], min, max, xlims=(min, max))
        Plots.plot!(x -> r, linetype=:vline, xlims=(min, max))
    end
end

function intersect(l, m)
    y = (l[1]*m[3] - l[3]*m[1])/(l[2]*m[1] - l[1]*m[2])
    x = (l[3]*m[2] - l[2]*m[3])/(l[2]*m[1] - l[1]*m[2])
    return [x y]
end

# all these constraints mean a*x + b*y + c >= 0
function lp_visualization(arr)
    valid_pts = []
    explored = []
    prev_i = -1
    i = 1
    ct = 0
    for x in 1:size(arr,1)
        yes = 0
        while i in explored
            i += 1
        end

        push!(explored, i)

        for j in 1:size(arr,1)
            if j == prev_i || i == j
                continue
            end

            pt = intersect(arr[i,:], arr[j,:])
            num_satisfied = 0
            for k in 1:size(arr, 1)
                if arr[k,1] * pt[1] + arr[k,2] * pt[2] + arr[k,3] >= 0
                    num_satisfied = num_satisfied + 1
                end
            end

            if num_satisfied == size(arr,1)
                yes = 1
                valid_pts = [valid_pts; pt]
                ct += 1
                if ct == 2
                    ct = 1
                    prev_i = i
                    i = j
                    break
                end
            end
        end

        if yes == 0
            i = 1
        end
    end

    if size(valid_pts, 1) == 0
        println("Infeasible Problem!!!")
        return
    end

    x = valid_pts[:,1]
    y = valid_pts[:,2]

    return valid_pts
end

function plotGivenModel(m)
    JuMP.build(m)
    A = MathProgBase.getconstrmatrix(internalmodel(m))
    x = MathProgBase.getconstrLB(internalmodel(m))

    rows = MathProgBase.numconstr(m)
    cols = MathProgBase.numvar(m) + 1
    arr = zeros(rows, cols)

    for i=1:rows
        for j=1:cols-1
            arr[i,j] = A[i,j]
        end
        arr[i,cols] = -x[i]
    end

    #arr = [2 2 -4; -2 4 2; -2 1 8; 2 -1 -2]
    valid_pts = lp_visualization(arr)
    valid_pts = convert(Array{Float64,2}, valid_pts)

    xdiff = maximum(valid_pts[:,1]) - minimum(valid_pts[:,1])
    ydiff = maximum(valid_pts[:,2]) - minimum(valid_pts[:,2])

    arr = [arr; 1 0 -(minimum(valid_pts[:,1]) - 2*xdiff); -1 0 (maximum(valid_pts[:,1]) + 2*xdiff)]
    arr = [arr; 0 1 -(minimum(valid_pts[:,2]) - 2*ydiff); 0 -1 (maximum(valid_pts[:,2]) + 2*ydiff)]

    xs = [minimum(valid_pts[:,1]) - 1.5*xdiff, (maximum(valid_pts[:,1]) + 1.5*xdiff)]
    ys = [minimum(valid_pts[:,2]) - 1.5*ydiff, (maximum(valid_pts[:,2]) + 1.5*ydiff)]

    valid_pts = lp_visualization(arr)
    valid_pts = convert(Array{Float64,2}, valid_pts)

    obj = MathProgBase.getobj(internalmodel(m))

    gr()
    @manipulate for r in floor(xs[1]):0.1:ceil(xs[2])
        plot(valid_pts[:,1], valid_pts[:,2], xlims=xs, ylims=ys)
        plot!(x -> (r-x*obj[1]) / obj[2], xlims=xs, ylims=ys)
    end
end

end # module
