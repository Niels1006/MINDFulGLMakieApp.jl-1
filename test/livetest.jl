#=
livetest:
- Julia version: 1.9.1
- Author: Niels
- Date: 2023-07-12
=#

using MINDFulGLMakieApp
MFA = MINDFulGLMakieApp

export run
function run()
    MFA.startup()
end

function test()
    testing()


end

