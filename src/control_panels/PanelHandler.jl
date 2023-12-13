struct Colors_
    red
    green
end

global colors = Colors_(
    RGBf(1, 0, 0),
    RGBf(39 / 255, 201 / 255, 104 / 255)
)



Base.@kwdef mutable struct MemberVariables
    fig

    graphs
    fullscreen_graph

    interactables
    interactables_observables

    displayed_graphs

    loaded_intents
    ibns


    grid_length
    topologies

end

function generate_grid_layout!(fig)
    gl = fig[1:2, 1:2] = GridLayout()
    fig[1, 1][1:2, 1:2] = GridLayout()
    return gl
end

function delete_all_interactables_from_screen(member_variables)

    for (k, v) in member_variables.interactables
        for (k2, v2) in v
            if typeof(v2) in [Makie.Menu, Makie.Button, Makie.Textbox, Makie.Label, Makie.Toggle]
                delete!(v2)
            else
                for (k3, v3) in v2
                    if typeof(v3) in [Makie.Menu, Makie.Button, Makie.Textbox, Makie.Label, Makie.Toggle]
                        delete!(v3)
                    end
                end
            end
        end
    end
end

function delete_all_graphs_from_screen(member_variables)
    for (k, v) in member_variables.graphs
        delete!(member_variables.graphs[k]["args"]["a"])
    end

end




function initialize_control_panel(member_variables)

    delete_all_interactables_from_screen(member_variables)

    fig = member_variables.fig
    member_variables.interactables["general"]["menu"] = Menu(fig[1, 1][1, 1][1, 0:1], options=["Intent Creation", "Intent Actions", "Draw", "UI Options"], default=member_variables.interactables_observables["general"]["menu"][])

    # check what type of control panel needs to be displayed 

    if member_variables.interactables_observables["general"]["menu"][] == "Intent Creation"
        init_control_panel_intents(member_variables)
    elseif member_variables.interactables_observables["general"]["menu"][] == "Draw"
        if length(member_variables.loaded_intents) > 0
            init_control_panel_drawing(member_variables)
        else
            member_variables.interactables_observables["general"]["menu"][] = "Intent Creation"
            initialize_control_panel(member_variables)
        end

    elseif member_variables.interactables_observables["general"]["menu"][] == "Intent Actions"
        if length(member_variables.loaded_intents) > 0
            init_control_panel_intent_actions(member_variables)
        else
            member_variables.interactables_observables["general"]["menu"][] = "Intent Creation"
            initialize_control_panel(member_variables)
        end

    elseif member_variables.interactables_observables["general"]["menu"][] == "UI Options"
        init_control_panel_ui_options(member_variables)
    end

    #add listerners for observables
    for (k, v) in member_variables.interactables
        for (k2, v2) in v
            if typeof(v2) == Makie.Menu
                on(v2.selection) do s
                    println(s)
                    member_variables.interactables_observables[k][k2][] = s
                end
            end
        end
    end



end



function main!(fig)
    #@async serve_repl()

    member_variables = init_member_variables!(fig)

    gl = generate_grid_layout!(fig)
    gl_2 = GridLayout()
    gl_hidden = GridLayout(bbox=BBox(-4000, -4000, -1000, -1000))

    gl_hidden[1:2, 1:2] = gl_2

    initialize_control_panel(member_variables)

    on(member_variables.interactables_observables["general"]["menu"]) do s
        initialize_control_panel(member_variables)
    end

    on(member_variables.interactables_observables["drawing"]["buttons"]["fullscreen"]) do s
        pos = member_variables.interactables["drawing"]["menus"]["draw_position"].selection[]
        pos_1, pos_2 = get_pos1_pos2(pos, member_variables.grid_length)
        member_variables.fig[2, 2], member_variables.fig[pos_1, pos_2] = content(member_variables.fig[pos_1, pos_2]), content(member_variables.fig[2, 2])
        #member_variables.fullscreen_graph = copy(member_variables.graphs)


        #println(pos_1, pos_2)
        #

        #gl_2[2,1] = fullscreen_graph
        #gl_2[2,2] = fullscreen_graph


        #delete_all_interactables_from_screen(member_variables)
        #delete_all_graphs_from_screen(member_variables)

        #member_variables.fig[2, 2] = fullscreen_graph

        member_variables.interactables["drawing"]["buttons"]["end_fullscreen"] = Button(fig[1, 1], label="End Fullscreen")
        on(member_variables.interactables["drawing"]["buttons"]["end_fullscreen"].clicks) do r
            member_variables.interactables_observables["drawing"]["buttons"]["end_fullscreen"][] = !member_variables.interactables_observables["drawing"]["buttons"]["end_fullscreen"][]
            delete!(member_variables.interactables["drawing"]["buttons"]["end_fullscreen"])
            #init_control_panel_drawing(member_variables)

            #gl[pos_1, pos_2] = fullscreen_graph
            member_variables.fig[1:2, 1:2] = gl
            gl_hidden[1:2, 1:2] = gl_2

            member_variables.fig[2, 2], member_variables.fig[pos_1, pos_2] = content(member_variables.fig[pos_1, pos_2]), content(member_variables.fig[2, 2])
        end



        member_variables.fig[1:2, 1:2] = gl_2
        gl_hidden[1:2, 1:2] = gl


        GLMakie.trim!(fig.layout)

    end


    return member_variables.fig


end

function init_member_variables!(fig)
    member_variables = MemberVariables(
        fig=fig,
        graphs=Dict(           #
        ),
        fullscreen_graph=Dict(),
        interactables=Dict(
            "general" => Dict(
                "menu" => Menu(fig[1, 1][1, 1][1, 1], options=["a"])
            ),
            "intents" => Dict(
                "buttons" => Dict(
                    "create_new_intent" => Button(fig[1, 1][1, 1][1, 1], label="a"),
                    "save_intent" => Button(fig[1, 1][1, 1][1, 1], label="a"),
                    "delete_intent" => Button(fig[1, 1][1, 1][1, 1], label="a")
                ),
                "menus" => Dict(
                    "topology" => Menu(fig[1, 1][1, 1][1, 1], options=["a"]),
                    "subnet" => Menu(fig[1, 1][1, 1][1, 1], options=["a"]),
                    "node_1" => Menu(fig[1, 1][1, 1][1, 1], options=["a"]),
                    "node_1_subnet" => Menu(fig[1, 1][1, 1][1, 1], options=["a"]),
                    "node_2" => Menu(fig[1, 1][1, 1][1, 1], options=["a"]),
                    "node_2_subnet" => Menu(fig[1, 1][1, 1][1, 1], options=["a"]),
                    "speed" => Menu(fig[1, 1][1, 1][1, 1], options=["a"]),
                    "intent_list" => Menu(fig[1, 1][1, 1][1, 1], options=["a"]),
                    "loaded_intents" => Menu(fig[1, 1][1, 1][1, 1], options=["a"]),
                ),
                "textboxes" => Dict(
                )
            ),
            "drawing" => Dict(
                "menus" => Dict(
                    "loaded_intents" => Menu(fig[1, 1][1, 1][1, 1], options=["a"]),
                    "draw_position" => Menu(fig[1, 1][1, 1][1, 1], options=["a"])
                ),
                "buttons" => Dict(
                    "draw" => Button(fig[1, 1][1, 1][1, 1], label="a")
                )
            ),
            "intent_actions" => Dict(
                "menus" => Dict(
                ),
                "buttons" => Dict(
                )
            ),
            "ui_options" => Dict(
                "toggles" => Dict(
                ),
                "labels" => Dict(
                )
            )
        ),
        interactables_observables=Dict(
            "general" => Dict(
                "menu" => Observable("Intent Creation")
            ),
            "intents" => Dict(
                "menus" => Dict(
                    "topology" => 1,
                    "subnet" => 1,
                    "node_1" => 1,
                    "node_1_subnet" => 1,
                    "node_2" => 1,
                    "node_2_subnet" => 1,
                    "ibn" => 1)
            ),
            "intent_actions" => Dict(
                "menus" => Dict(
                    "loaded_intents" => 1,
                    "compilation_algorithm" => 1
                )
            ),
            "drawing" => Dict(
                "buttons" => Dict(
                    "fullscreen" => Observable(false),
                    "end_fullscreen" => Observable(false)
                ),
                "menus" => Dict(
                    "loaded_intents" => 1,
                    "draw_position" => 1,
                    "intent-visualization" => 1,
                    "domain_to_draw" => 1
                )
            ),
            "ui_options" => Dict(
                "toggles" => Dict(
                    "save_options_intent_creation" => true,
                    "save_options_intent_actions" => true,
                    "save_options_draw" => true
                )
            )
        ), displayed_graphs=nothing,
        loaded_intents=[
        ],
        ibns=[
        ],
        grid_length=2, topologies=[
            Dict(
                "name" => "4nets",
                "relative" => false,
                "path" => joinpath("data/" * "4nets.graphml")
            )
        ]
    )

    return member_variables
end

function startup()
    fig = Figure(resolution=(1800, 1200))
    fig_configured = main!(fig)
    display(fig_configured)
    set_theme!(fontsize=25)
    #readline()

end

export startup