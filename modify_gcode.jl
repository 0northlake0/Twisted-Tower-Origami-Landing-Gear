using DelimitedFiles


# check if current layer should be modified
check_layer() = (round(Int, 10*layer) % 153) in 118:154


function change_layer(new_layer)
    # correct old layer, if necessary
    if check_layer()
        iis = findindices()
        for x in 0:nb_prll-1
            swaploops(iis[1 + x*4], iis[2 + x*4], iis[3 + x*4], iis[4 + x*4])
        end
    end
    # change to new layer and initialize changes
    global layer = new_layer
    global changes = [lastindex(new)]
end


function findindices()
    # find and return start and end of print moves to be swapped
    res = []
    for i in 1:length(changes)-1
        if changes[i+1] - changes[i] > 50
            push!(res, changes[i])
            push!(res, changes[i+1])
        end
    end
    return res
end

function swaploops(i1, i2, i3, i4)
    # swap print moves
    global new = reduce(vcat, [new[1:i1-1], new[i3:i4-1], new[i2:i3-1], new[i1:i2-1], new[i4:end]])
end


# settings
nb_prll = 2 # nb of samples printed on one build plate concurrently

# global variables
layer = 0 # current layer
changes = []

# text arrays
original = readlines("2x2x8_0.1mm_FLEX_MK3S_2h5m.gcode")
new = []

# main loop through each line
for line in original
    a = tryparse(Float64, line[2:end])
    if (a !== nothing) && (a != layer) && (a < 40.0) # check for change of layer
        change_layer(a)
        push!(new, line)
    elseif occursin("F10800", line) # check for new, distinct print move, often accompanied by retraction and travel
        push!(changes, lastindex(new)+1)
        push!(new, line)
    else
        push!(new, line)
    end
end

# ouput
writedlm("2modified8x2.gcode", new, quotes=false)
