class 'FunctionUtilities'

function FunctionUtilities:IsFunction(Func)
    return Func and _G.type(Func) == 'function' 
end

function FunctionUtilities:RightPadding(Str, Length, Character)
    local Res = Str .. string.rep(Character or ' ', Length - #Str)
    return Res, Res ~= Str
end

local Instance = FunctionUtilities()
return Instance