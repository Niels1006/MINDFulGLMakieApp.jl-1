function init_control_panel_drawing(member_variables)
    fig = member_variables.fig
    #Menus
    member_variables.interactables["drawing"]["menus"]["loaded_intents"] = Menu(fig[1, 1][1, 1][1, 2:5],
        options=[v["name"] for v in member_variables.loaded_intents])
    member_variables.interactables["drawing"]["menus"]["draw_position"] = Menu(fig[1, 1][1, 1][4, 2:5],
        options=[i for i in 1:member_variables.grid_length*member_variables.grid_length-1])
    member_variables.interactables["drawing"]["menus"]["intent-visualization"] = Menu(fig[1, 1][1, 1][3, 2:5],
        options=["ibnplot", "intentplot"])
    member_variables.interactables["drawing"]["menus"]["domain_to_draw"] = Menu(fig[1, 1][1, 1][2, 2:5],
        options=["All"])



    #Buttons
    member_variables.interactables["drawing"]["buttons"]["draw"] = Button(fig[1, 1][1, 1][2, 0:1], label="Draw")
    #member_variables.interactables["drawing"]["buttons"]["pop_out"] = Button(fig[1, 1][1, 1][3, 0:1], label="Pop out draw")
    member_variables.interactables["drawing"]["buttons"]["delete"] = Button(fig[1, 1][1, 1][4, 0:1], label="Delete")
    member_variables.interactables["drawing"]["buttons"]["fullscreen"] = Button(fig[1, 1][1, 1][3, 0:1], label="Fullscreen")

    #member_variables.interactables["drawing"]["buttons"]["move"] = Button(fig[1, 1][1, 1][5, 4:5], label="Move")




    #Button Listeners
    on(member_variables.interactables["drawing"]["buttons"]["draw"].clicks) do s
        draw(wrap_current_draw_args_in_dict(member_variables), member_variables)

        update_menu_colors_drawing(member_variables)
    end

    on(member_variables.interactables["drawing"]["buttons"]["delete"].clicks) do s
        pos = member_variables.interactables["drawing"]["menus"]["draw_position"].selection[]
        delete!(member_variables.graphs[pos]["args"]["a"])
        delete!(member_variables.graphs, pos)

        update_menu_colors_drawing(member_variables)
    end

    on(member_variables.interactables["drawing"]["buttons"]["fullscreen"].clicks) do s
        member_variables.interactables_observables["drawing"]["buttons"]["fullscreen"][] = !member_variables.interactables_observables["drawing"]["buttons"]["fullscreen"][]
        println(member_variables.interactables_observables["drawing"]["buttons"]["fullscreen"][])
    end


    #Menu Listeners

    on(member_variables.interactables["drawing"]["menus"]["loaded_intents"].i_selected) do s
        if s > 1
            member_variables.interactables["drawing"]["menus"]["domain_to_draw"].options[] = append!(
                Any[member_variables.interactables["drawing"]["menus"]["domain_to_draw"].options[][1]], append!(
                    Any["All"], [find_intent_in_loaded_by_name(member_variables, member_variables.interactables["drawing"]["menus"]["loaded_intents"].selection[])["ibn_index"]]
                ))
        end
    end




    #update default labels

    prompts = Dict(
        "loaded_intents" => "Loaded Intents",
        "draw_position" => "Draw position",
        "intent-visualization" => "Plotting type",
        "domain_to_draw" => "Domain to draw"
    )
    for x in keys(prompts)
        member_variables.interactables["drawing"]["menus"][x].options[] = append!(Any[prompts[x]], member_variables.interactables["drawing"]["menus"][x].options[])
        if member_variables.interactables_observables["ui_options"]["toggles"]["save_options_draw"] == true
            index = member_variables.interactables_observables["drawing"]["menus"][x]
        else
            index = 1
        end
        println(index, member_variables.interactables_observables["drawing"]["menus"][x])
        member_variables.interactables["drawing"]["menus"][x].i_selected[] = index

    end

    #set all colors
    update_menu_colors_drawing(member_variables)

    for x in keys(prompts)
        on(member_variables.interactables["drawing"]["menus"][x].selection) do s
            update_menu_colors_drawing(member_variables)
        end
    end

    #update observables

    for x in ["loaded_intents", "draw_position", "intent-visualization", "domain_to_draw"]
        on(member_variables.interactables["drawing"]["menus"][x].i_selected) do s
            member_variables.interactables_observables["drawing"]["menus"][x] = s
            println("set to " .. string(s))

        end
    end



end

function wrap_current_draw_args_in_dict(member_variables)
    pos = member_variables.interactables["drawing"]["menus"]["draw_position"].selection[]
    graph_type = member_variables.interactables["drawing"]["menus"]["intent-visualization"].selection[]
    domain_to_draw = member_variables.interactables["drawing"]["menus"]["domain_to_draw"].selection[]
    if typeof(domain_to_draw) === String
        domain_to_draw = 0
    end

    if pos in keys(member_variables.graphs)
        println("Not clear canvas!")
        return
    end


    intent = find_intent_in_loaded_by_name(member_variables, member_variables.interactables["drawing"]["menus"]["loaded_intents"].selection[])

    args = Dict(
        "graph_type" => graph_type,
        "intent" => intent,
        "pos" => pos,
        "domain_to_draw" => domain_to_draw
    )

    member_variables.graphs[pos] = Dict(
        "args" => args
    )

    return args

end


function draw(args, member_variables; pop_out=false)
    if args === nothing
        return
    end

    fig = member_variables.fig
    if pop_out == true
        fig = Figure(resolution=(800, 800))
    end

    pos = args["pos"]
    pos_1, pos_2 = get_pos1_pos2(pos, member_variables.grid_length)

    a = Axis(fig[pos_1, pos_2], title="Graph " * string(pos) * ", Domain: " * string(args["domain_to_draw"]) *  ", Intent: " * args["intent"]["name"] * ", Algo: " * args["intent"]["algo"])
    member_variables.graphs[pos]["args"]["a"] = a

    plot_mindful(args["graph_type"], a, args["intent"]["ibn"], args["intent"]["id"], args["domain_to_draw"])
end

function update_menu_colors_drawing(member_variables)
    keys_ = ["loaded_intents", "draw_position", "intent-visualization", "domain_to_draw"]
    green_count = 0

    for x in keys_
        if member_variables.interactables["drawing"]["menus"][x].i_selected[] < 2
            member_variables.interactables["drawing"]["menus"][x].textcolor = colors.red
        else
            member_variables.interactables["drawing"]["menus"][x].textcolor = colors.green
            green_count += 1
        end
    end




    pos = member_variables.interactables["drawing"]["menus"]["draw_position"].selection[]
    if pos in keys(member_variables.graphs)
        member_variables.interactables["drawing"]["buttons"]["draw"].labelcolor = colors.red
        member_variables.interactables["drawing"]["buttons"]["delete"].labelcolor = colors.green


    else
        if green_count == length(keys_)
            member_variables.interactables["drawing"]["buttons"]["draw"].labelcolor = colors.green
        else
            member_variables.interactables["drawing"]["buttons"]["draw"].labelcolor = colors.red
        end

        member_variables.interactables["drawing"]["buttons"]["delete"].labelcolor = colors.red

    end

end