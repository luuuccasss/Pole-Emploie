Scaleform = {}

function Scaleform.IB(_buttons)
    local scaleform = RequestScaleformMovie("INSTRUCTIONAL_BUTTONS")
    if HasScaleformMovieLoaded(scaleform) then
        DrawScaleformMovie(scaleform, 0.5, 0.5, 1.0, 1.0, 255, 255, 255, 255)
        if not HasScaleformMovieLoaded(scaleform) then
            scaleform = RequestScaleformMovie("INSTRUCTIONAL_BUTTONS")
    
            while not HasScaleformMovieLoaded(scaleform) do
                Wait(0)
            end
        else
            scaleform = RequestScaleformMovie("INSTRUCTIONAL_BUTTONS")
    
            while not HasScaleformMovieLoaded(scaleform) do
                Wait(0)
            end
        end
    
        BeginScaleformMovieMethod(scaleform, "CLEAR_ALL")
        EndScaleformMovieMethodReturnValue()
    
        for i, btn in ipairs(_buttons) do
            BeginScaleformMovieMethod(scaleform, "SET_DATA_SLOT")
            ScaleformMovieMethodAddParamInt(i)
            ScaleformMovieMethodAddParamTextureNameString(GetControlInstructionalButton(0,btn[1],0))
            ScaleformMovieMethodAddParamTextureNameString(btn[2])
            EndScaleformMovieMethodReturnValue()
        end
    
        BeginScaleformMovieMethod(scaleform, "DRAW_INSTRUCTIONAL_BUTTONS")
        ScaleformMovieMethodAddParamInt(layout)
        EndScaleformMovieMethodReturnValue()
    end
end

function Scaleform.Request(scaleform)
    local scaleform_handle = RequestScaleformMovie(scaleform)
    while not HasScaleformMovieLoaded(scaleform_handle) do
        Citizen.Wait(0)
    end
    return scaleform_handle
end

function Scaleform.CallFunction(scaleform, returndata, the_function, ...)
    BeginScaleformMovieMethod(scaleform, the_function)
    local args = {...}

    if args ~= nil then
        for i = 1,#args do
            local arg_type = type(args[i])

            if arg_type == "boolean" then
                ScaleformMovieMethodAddParamBool(args[i])
            elseif arg_type == "number" then
                if not string.find(args[i], '%.') then
                    ScaleformMovieMethodAddParamInt(args[i])
                else
                    ScaleformMovieMethodAddParamFloat(args[i])
                end
            elseif arg_type == "string" then
                ScaleformMovieMethodAddParamTextureNameString(args[i])
            end
        end

        if not returndata then
            EndScaleformMovieMethod()
        else
            return EndScaleformMovieMethodReturnValue()
        end
    end
end