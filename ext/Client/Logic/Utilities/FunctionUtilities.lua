class 'FunctionUtilities'

function FunctionUtilities:IsFunction(Func)
    return Func and _G.type(Func) == 'function' 
end

local Instance = FunctionUtilities()
return Instance