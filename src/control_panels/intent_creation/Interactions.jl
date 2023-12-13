
function add_intent_to_member_variables(member_variables, n1, n1_sn, n2, n2_sn, speed, topology, sn, name="Your intent")
    dict = Dict(
        "name" => name,
        "node_1" => n1,
        "node_1_subnet" => n1_sn,
        "node_2" => n2,
        "node_2_subnet" => n2_sn,
        "speed" => speed,
        "topology" => topology,
        "subnet" => sn,
        "rolling_number" => time()
    )
    member_variables.loaded_intents[name] = dict

    sorted = sort(collect(zip(keys(member_variables.loaded_intents), values(member_variables.loaded_intents))), by=q -> q[2]["rolling_number"])
    member_variables.interactables["intents"]["menus"]["loaded_intents"].options = [v["name"] for (k, v) in sorted]
    member_variables.interactables["intents"]["menus"]["loaded_intents"].i_selected = length([v["name"] for (k, v) in sorted])
end


function init_control_panel_intents(member_variables)
    fig = member_variables.fig
    #Menus




    member_variables.interactables["intents"]["menus"]["topology"] = Menu(fig[1, 1][1, 1][1, 2:5])
    
    member_variables.interactables["intents"]["menus"]["node_1"] = Menu(fig[1, 1][1, 1][2, 2:3], options=["Domain NA"])
    member_variables.interactables["intents"]["menus"]["node_1_subnet"] = Menu(fig[1, 1][1, 1][2, 0:1], options=["Topology NA"])
    member_variables.interactables["intents"]["menus"]["node_2"] = Menu(fig[1, 1][1, 1][3, 2:3], options=["Domain NA"])
    member_variables.interactables["intents"]["menus"]["node_2_subnet"] = Menu(fig[1, 1][1, 1][3, 0:1], options=["Topology NA"])


    if length(member_variables.ibns) > 0
        member_variables.interactables["intents"]["menus"]["ibn"] = Menu(fig[1, 1][1, 1][2, 4:5], options=[["New Net"]; [v["name"] for v in member_variables.ibns]])
    else
        member_variables.interactables["intents"]["menus"]["ibn"] = Menu(fig[1, 1][1, 1][2, 4:5], options=["New Net"])
    end

    #Buttons
    member_variables.interactables["intents"]["buttons"]["create_new_intent"] = Button(fig[1, 1][1, 1][3, 4:5], label="Create")
    member_variables.interactables["intents"]["buttons"]["delete_topology"] = Button(fig[1, 1][1, 1][4, 4:5], label="Delete Top")
    #member_variables.interactables["intents"]["buttons"]["refresh_top"] = Button(fig[1, 1][1, 1][4, 4:5], label="Refresh Top")

    #text boxes
    member_variables.interactables["intents"]["textboxes"]["add_topology_path"] = Textbox(fig[1, 1][1, 1][4, 0:3], placeholder="Path to .graphml file", reset_on_defocus=true)
    #member_variables.interactables["intents"]["textboxes"]["speed"] = Textbox(fig[1, 1][1, 1][4, 0:1], placeholder="Speed in Gbps", reset_on_defocus=true)


    #Add labels to Menus

    names = Dict(
        "node_1" => "Node 1",
        "node_1_subnet" => "Domain 1",
        "node_2" => "Node 2",
        "node_2_subnet" => "Domain 2",
        "topology" => "Topology",
        "ibn" => "Frameworks",
        "speed" => "Speed"
    )

    for name in keys(names)
        member_variables.interactables["intents"]["menus"][name].options = append!(Any[names[name]], member_variables.interactables["intents"]["menus"][name].options[])
        member_variables.interactables["intents"]["menus"][name].i_selected = 1

    end

    #Textbox Listeners

    on(member_variables.interactables["intents"]["textboxes"]["add_topology_path"].stored_string) do s
        if s != member_variables.interactables["intents"]["textboxes"]["add_topology_path"].placeholder[]
            member_variables.interactables["intents"]["textboxes"]["add_topology_path"].stored_string = member_variables.interactables["intents"]["textboxes"]["add_topology_path"].placeholder[]
            if append_toplogy_to_file(s)
                reload_toplogies(member_variables)
            end

        end
    end


    #Button Listeners
    on(member_variables.interactables["intents"]["buttons"]["create_new_intent"].clicks) do s
        _v = member_variables.interactables["intents"]["menus"]
        _t = member_variables.interactables["intents"]["textboxes"]

        if member_variables.interactables["intents"]["menus"]["ibn"].selection[] == "New Net"
            idi, ibn = init_intent(_v["node_1"].selection[],
                _v["node_1_subnet"].selection[],
                _v["node_2"].selection[],
                _v["node_2_subnet"].selection[],
                #parse(Int64, _t["speed"].stored_string[]),
                _v["topology"].selection[],
                _v["subnet"].selection[],
                member_variables,
                myibns=nothing)

            counter = 1

            for i in 1:length(member_variables.ibns)
                if occursin(_v["topology"].selection[], member_variables.ibns[i]["name"])
                    counter += 1
                end
            end

            name = _v["topology"].selection[] * " " * string(counter)
            append!(member_variables.ibns, [Dict("name" => name, "ibn" => ibn)])
            member_variables.interactables["intents"]["menus"]["ibn"].options = [member_variables.interactables["intents"]["menus"]["ibn"].options[]; name]

            intent_name = name * ", " * string(idi.value, base=16)

        else
            ibn_ar_index = findall(x -> x["name"] == member_variables.interactables["intents"]["menus"]["ibn"].selection[], member_variables.ibns)[1]


            idi, ibn = init_intent(_v["node_1"].selection[],
                _v["node_1_subnet"].selection[],
                _v["node_2"].selection[],
                _v["node_2_subnet"].selection[],
                #_v["speed"].selection[],
                _v["topology"].selection[],
                _v["subnet"].selection[],
                member_variables,
                myibns=member_variables.ibns[ibn_ar_index]["ibn"])

            intent_name = member_variables.ibns[ibn_ar_index]["name"] * ", " * string(idi.value, base=16)

        end






        append!(member_variables.loaded_intents, [Dict("id" => idi, "ibn" => ibn, "name" => intent_name, "algo" => "", "topology" => _v["topology"].selection[], "ibn_index" => _v["node_1_subnet"].selection[])])

        member_variables.interactables["intents"]["menus"]["loaded_intents"].options = [member_variables.interactables["intents"]["menus"]["loaded_intents"].options[]; intent_name]


        for _a in ["node_1", "node_1_subnet", "node_2", "node_2_subnet", "topology", "subnet", "speed"]
            println(_a, ":   ", _v[_a].selection[])
        end


    end

    on(member_variables.interactables["intents"]["buttons"]["delete_topology"].clicks) do s
        name = member_variables.interactables["intents"]["menus"]["topology"].selection[]
        index = findfirst(x -> x["name"] == name, member_variables.topologies)
        top = member_variables.topologies[index]
        delete_toplogy_from_file(top["path"])
        reload_toplogies(member_variables)
    end


    #= on(member_variables.interactables["intents"]["buttons"]["refresh_top"].clicks) do s
        member_variables.interactables["intents"]["menus"]["topology"].options[] = get_graph_names()
    end
    =#

    #Menu Listeners

    #Topology menu
    on(member_variables.interactables["intents"]["menus"]["topology"].selection) do s
        if member_variables.interactables["intents"]["menus"]["topology"].i_selected[] > 1
            for x in ["node_1", "node_1_subnet", "node_2", "node_2_subnet"]
                set_menu_selected(member_variables.interactables["intents"]["menus"][x])
            end


            subnet_amount = get_subnet_amount(s, member_variables)
            for x in ["node_1_subnet", "node_2_subnet"]
                member_variables.interactables["intents"]["menus"][x].options = append!(Any[member_variables.interactables["intents"]["menus"][x].options[][1]], [i for i in 1:subnet_amount])
            end
        end

    end

    #domain menu
    for x in ["node_1", "node_2"]
        on(member_variables.interactables["intents"]["menus"][x*"_subnet"].selection) do s
            if s != member_variables.interactables["intents"]["menus"][x*"_subnet"].options[][1]
                domain_i = s
                top = member_variables.interactables["intents"]["menus"]["topology"].selection[]

                idi, ibn = init_intent(1,
                    domain_i,
                    1,
                    domain_i,
                    #2,
                    top,
                    domain_i,
                    member_variables)

                domain_amount = length(get_nodes_of_subdomain(ibn[domain_i]))
                member_variables.interactables["intents"]["menus"][x].options[] = append!(Any[member_variables.interactables["intents"]["menus"][x].options[][1]], 1:domain_amount)
                set_menu_selected(member_variables.interactables["intents"]["menus"][x])
            end

        end
    end

    update_menu_colors_ic(member_variables)

    for x in ["node_1", "node_1_subnet", "node_2", "node_2_subnet", "topology", "ibn"]
        on(member_variables.interactables["intents"]["menus"][x].selection) do s
            update_menu_colors_ic(member_variables)
            member_variables.interactables_observables["intents"]["menus"][x] = member_variables.interactables["intents"]["menus"][x].i_selected[]
        end
    end

    reload_toplogies(member_variables)

    #Load saved menu options
    if member_variables.interactables_observables["ui_options"]["toggles"]["save_options_intent_creation"] == true
        #member_variables.interactables["intents"]["menus"]["topology"].i_selected[] = member_variables.interactables_observables["intents"]["menus"]["topology"]
        #member_variables.interactables["intents"]["menus"]["node_1_subnet"].i_selected[] = 3
        
        for x in ["topology", "ibn", "node_1_subnet", "node_1", "node_2_subnet", "node_2"]
            member_variables.interactables["intents"]["menus"][x].i_selected[] = member_variables.interactables_observables["intents"]["menus"][x]
        end

    end

    



end

function reload_toplogies(member_variables)
    member_variables.interactables["intents"]["menus"]["topology"].i_selected = 1

    topologies = get_topologies_from_file()



    new_top_ar = Dict[]

    for x in topologies
        seperator = ""
        if occursin("/", x)
            seperator = "/"
        elseif occursin("\\", x)
            seperator = "\\"
        end

        name = replace(last(split(x, seperator)), ".graphml" => "")

        append!(new_top_ar, [Dict(
            "name" => name,
            "relative" => false,
            "path" => x
        )])
    end

    member_variables.topologies = copy(new_top_ar)
    member_variables.interactables["intents"]["menus"]["topology"].options = append!([member_variables.interactables["intents"]["menus"]["topology"].options[][1]], [x["name"] for x in new_top_ar])

end

function update_menu_colors_ic(member_variables)
    keys = ["node_1", "node_1_subnet", "node_2", "node_2_subnet", "topology", "ibn"]
    green_count = 0

    for x in keys
        if member_variables.interactables["intents"]["menus"][x].i_selected[] == 1
            member_variables.interactables["intents"]["menus"][x].textcolor = colors.red
        else
            member_variables.interactables["intents"]["menus"][x].textcolor = colors.green
            green_count += 1
        end
    end

    if green_count == length(keys)
        member_variables.interactables["intents"]["buttons"]["create_new_intent"].labelcolor = colors.green
    else
        member_variables.interactables["intents"]["buttons"]["create_new_intent"].labelcolor = colors.red
    end

    #delete top colors
    if member_variables.interactables["intents"]["menus"]["topology"].i_selected[] > 1
        member_variables.interactables["intents"]["buttons"]["delete_topology"].labelcolor = colors.green
    else
        member_variables.interactables["intents"]["buttons"]["delete_topology"].labelcolor = colors.red
    end
end