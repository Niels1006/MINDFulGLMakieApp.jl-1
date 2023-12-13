function init_control_panel_ui_options(member_variables)
    fig = member_variables.fig

    #Toggles
    member_variables.interactables["ui_options"]["toggles"]["save_options_intent_creation"] = Toggle(
        fig[1, 1][1, 1][1, 2:3], active=member_variables.interactables_observables["ui_options"]["toggles"]["save_options_intent_creation"][])
    member_variables.interactables["ui_options"]["toggles"]["save_options_intent_actions"] = Toggle(
        fig[1, 1][1, 1][2, 2:3], active=member_variables.interactables_observables["ui_options"]["toggles"]["save_options_intent_actions"][])
    member_variables.interactables["ui_options"]["toggles"]["save_options_draw"] = Toggle(
        fig[1, 1][1, 1][3, 2:3], active=member_variables.interactables_observables["ui_options"]["toggles"]["save_options_draw"][])

    #Labels
    member_variables.interactables["ui_options"]["labels"]["save_options_intent_creation"] = Label(fig[1, 1][1, 1][1, 4:6], "Save Intent Creation Menu Options"; justification =:left)
    member_variables.interactables["ui_options"]["labels"]["save_options_intent_actions"] = Label(fig[1, 1][1, 1][2, 4:6], "Save Intent Actions Options"; justification =:left)
    member_variables.interactables["ui_options"]["labels"]["save_options_draw"] = Label(fig[1, 1][1, 1][3, 4:6], "Save Draw Menu Options"; justification =:left)


    for x in ["save_options_intent_creation", "save_options_intent_actions", "save_options_draw"]
        on(member_variables.interactables["ui_options"]["toggles"][x].active) do s
            member_variables.interactables_observables["ui_options"]["toggles"][x] = s
        end
    end


end