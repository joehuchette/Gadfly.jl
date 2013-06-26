
# Data binds untyped values to a aesthetic variables.
# TODO: generate this from Aesthetics with a macro
type Data
    x
    y
    x_min
    x_max
    y_min
    y_max
    xtick
    ytick
    xtick_labels
    ytick_labels
    x_viewmin
    x_viewmax
    y_viewmin
    y_viewmax
    size
    color
    label

    function Data()
        new(nothing, nothing, nothing, nothing,
            nothing, nothing, nothing, nothing,
            nothing, nothing, nothing, nothing,
            nothing, nothing, nothing, nothing,
            nothing)
    end

    # shallow copy constructor
    function Data(a::Data)
        b = new()
        for name in Data.names
            setfield(b, name, getfield(a, name))
        end
        b
    end
end

# Make a shallow copy of a Data instance.
#
# Args:
#   a: source
#
# Returns:
#   A copy of a
#
copy(a::Data) = Data(a)


# Produce a new Data instance chaining the values of one or more others.
#
# The bound values in the returned Data instance are chain iterators which will
# iterate through the values contained in all the given Data instances.
#
# Args:
#  ds: Some Data instances.
#
# Returns:
#   A new Data instance.
#
function chain(ds::Data...)
    chained_data = Data()
    for name in Data.names
        vs = {getfield(d, name) for d in ds}
        vs = {v for v in filter(issomething, vs)}
        if isempty(vs)
            setfield(chained_data, name, nothing)
        else
            setfield(chained_data, name, Iterators.chain(vs...))
        end
    end

    chained_data
end



# Convert to a simple type that can be trivially serialized.
function serialize(data::Data)
    out = Dict()
    for name in Data.names
        if !is(getfield(data, name), nothing)
            out[name] = serialize(getfield(data, name))
        end
    end
    out
end


function deserialize(::Type{Data}, data::Dict)
    out = Data()
    for (name, value) in data
        setfield(out, name,
                 deserialize(eval(symbol(value["type"])), value["value"]))
    end
    out
end


# Serialization/deserialization of common types

function serialize(data::DataArray)
    # Replace NA with nothing/null
    arr = Array(Any, length(data))
    for (i, x) in enumerate(data)
        if x === NA
            arr[i] = nothing
        else
            arr[i] = x
        end
    end

    {
        "type"  => "DataArray",
        "value" => arr
    }
end


function serialize(data::Real)
    # TODO: special handling of 64-bit inegers, since javascript might screw these up.
    {
        "type"  => string(typeof(data)),
        "value" => data
    }
end


function serialize(data::String)
    {
        "type"  => "String",
        "value" => data
    }
end


function deserialize(::Type{DataArray}, data::Array)
    arr = Array(Any, length(data))
    for (i, x) in enumerate(data)
        if x === nothing
            arr[i] = NA
        else
            arr[i] = x
        end
    end
    DataArray(arr)
end


deserialize{T <: Real}(::Type{T}, data) = convert(T, data)
deserialize(::Type{String}, data) = data

