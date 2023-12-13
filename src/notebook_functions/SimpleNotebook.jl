using MINDFul, GraphIO, NestedGraphsIO, NestedGraphs, Graphs, MetaGraphs

using MINDFulMakie, GLMakie, Unitful


function plot_mindful(plot_type, axis, ibn, idi, domain)
    if plot_type == "intentplot"
        if domain == 0
            intentplot!(axis, ibn, idi)
        else
            intentplot!(axis, ibn[domain], idi)
        end
    elseif plot_type == "ibnplot"
        if domain == 0
            ibnplot!(axis, ibn, intentidx=[idi])
        else
            ibnplot!(axis, ibn[domain], intentidx=[idi])
        end

    end
end


function create_intent(node_1, node_2, subnet_1, subnet_2)
    myintent = ConnectivityIntent((subnet_1.id, node_1), (subnet_2.id, node_2), 50)
    return myintent
end

function add_intent_to_framework(intent, ibn)
    idi = addintent!(ibn, intent)
    return idi
end

function init_intent(n1, n1_sn, n2, n2_sn, topology, sn, member_variables; myibns=nothing)
    top_dict = nothing

    for top in member_variables.topologies
        if top["name"] == topology
            top_dict = top
        end
    end



    if myibns === nothing
        myibns = load_ibn(top_dict["path"])
    end
    local myintent = create_intent(n1, n2, myibns[n1_sn], myibns[n2_sn])
    local idi = add_intent_to_framework(myintent, myibns[n1_sn])
    return idi, myibns
end


function deploy_intent(ibn, idi, algorithm)
    if algorithm == "shortestavailpath"
        algo = MINDF.shortestavailpath!
    elseif algorithm == "jointrmsagenerilizeddijkstra"
        algo = MINDFulCompanion.jointrmsagenerilizeddijkstra!
    elseif algorithm == "longestavailpath"
        algo = longestavailpath!
    end


    deploy!(ibn, idi, MINDF.docompile, MINDF.SimpleIBNModus(), algo; time=nexttime())
end

function install_intent(ibn, idi)
    deploy!(ibn, idi, MINDF.doinstall, MINDF.SimpleIBNModus(), MINDF.directinstall!; time=nexttime())
end

function uninstall_intent(ibn, idi)
    deploy!(ibn, idi, MINDF.douninstall, MINDF.SimpleIBNModus(),  MINDF.directuninstall!; time=nexttime())
end

function uncompile_intent(ibn, idi)
    deploy!(ibn, idi, MINDF.douncompile, MINDF.SimpleIBNModus(); time=nexttime())
end

function remove_intent(ibn, idi)
    remintent!(ibn, idi)
end


function load_ibn(topology_path)
    # read in the NestedGraph
    globalnet = open(joinpath(topology_path)) do io
        loadgraph(io, "main", GraphIO.GraphML.GraphMLFormat(), NestedGraphs.NestedGraphFormat())
    end

    # convert it to a NestedGraph compliant with the simulation specifications
    simgraph = MINDF.simgraph(globalnet;
        distance_method=MINDF.euclidean_dist,
        router_lcpool=defaultlinecards(),
        router_lccpool=defaultlinecardchassis(),
        router_lcccap=3,
        transponderset=defaulttransmissionmodules())

    # convert it to IBNs
    myibns = MINDFul.nestedGraph2IBNs!(simgraph)

    return myibns
end


defaultlinecards() = [MINDF.LineCardDummy(10, 100, 26.72), MINDF.LineCardDummy(2, 400, 29.36), MINDF.LineCardDummy(1, 1000, 31.99)]
defaultlinecardchassis() = [MINDF.LineCardChassisDummy(Vector{MINDF.LineCardDummy}(), 4.7, 16)]
defaulttransmissionmodules() = [MINDF.TransmissionModuleView("DummyFlexibleTransponder",
        MINDF.TransmissionModuleDummy([MINDF.TransmissionProps(5080.0u"km", 300, 8),
                MINDF.TransmissionProps(4400.0u"km", 400, 8),
                MINDF.TransmissionProps(2800.0u"km", 500, 8),
                MINDF.TransmissionProps(1200.0u"km", 600, 8),
                MINDF.TransmissionProps(700.0u"km", 700, 10),
                MINDF.TransmissionProps(400.0u"km", 800, 10)], 0, 20)),
    MINDF.TransmissionModuleView("DummyFlexiblePluggables",
        MINDF.TransmissionModuleDummy([MINDF.TransmissionProps(5840.0u"km", 100, 4),
                MINDF.TransmissionProps(2880.0u"km", 200, 6),
                MINDF.TransmissionProps(1600.0u"km", 300, 6),
                MINDF.TransmissionProps(480.0u"km", 400, 6)], 0, 8))
]
nexttime() = MINDF.COUNTER("time")u"hr"


function longestavailpath!(ibn::IBN, idagnode::IntentDAGNode{R}, ::MINDF.IntraIntent; time, k = 100) where {R<:ConnectivityIntent}
    conint = getintent(idagnode)
    source = MINDF.localnode(ibn, getsrc(conint); subnetwork_view=false)
    dest = MINDF.localnode(ibn, getdst(conint); subnetwork_view=false)

    yenpaths = yen_k_shortest_paths(MINDF.getgraph(ibn), source, dest, MINDF.linklengthweights(ibn), k)
	# call an internal function that picks the first available path
	# use the first fil spectrum alocation algorithm as before (https://ieeexplore.ieee.org/document/6421472)
    MINDF.deployfirstavailablepath!(ibn, idagnode, reverse(yenpaths.paths), reverse(yenpaths.dists); spectrumallocfun=MINDF.firstfit, time)
    return getstate(idagnode)
end


function get_nodes_of_subdomain(ibn)
    #println(fieldnames(typeof(ibn)))
    return MINDFul.getmynodes(ibn)
end
