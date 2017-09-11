using JuliaWebAPI
using Compat
using ZMQ

# include("core.jl")

# Define functions testfn1 and testfn2 that we shall expose
function testfn1(arg1, arg2; narg1=1, narg2=2)
    return (parse(Int, arg1) * parse(Int, narg1)) + (parse(Int, arg2) * parse(Int, narg2))
end

testfn2(arg1, arg2; narg1=1, narg2=2) = testfn1(arg1, arg2; narg1=narg1, narg2=narg2)


# Expose testfn1 and testfn2 via a ZMQ listener
const Cross_origin_JSON = Dict{Compat.UTF8String,Compat.UTF8String}("Content-Type" => "application/json; charset=utf-8", "Access-Control-Allow-Origin" => "http://localhost:3000")
const JSON_RESP_HDRS = Dict{String,String}("Content-Type" => "application/json; charset=utf-8")
const SRVR_ADDR = "tcp://127.0.0.1:9999"

function run_srvr(fmt, tport, async=false, open=false)
    # Logging.configure(level=INFO, filename="apisrvr_test.log")
    # Logging.info("queue is at $SRVR_ADDR")

    api = APIResponder(tport, fmt, nothing, open)
    # Logging.info("responding with: $api")

    register(api, testfn1; resp_json=true, resp_headers=JSON_RESP_HDRS)
    register(api, testfn2; resp_json=true, resp_headers=Cross_origin_JSON)

    process(api; async=async)
end

function run_httprpcsrvr(fmt, tport, async=false)
    run_srvr(fmt, tport, true, true)
    apiclnt = APIInvoker(ZMQTransport(SRVR_ADDR, REQ, false), fmt)
    if async
        @async run_http(apiclnt, 8888)
    else
        run_http(apiclnt, 8888)
    end
end

function wait_for_httpsrvr()
    while true
        try
            sock = connect("localhost", 8888)
            close(sock)
            return
        catch
            Logging.info("waiting for httpserver to come up at port 8888...")
            sleep(5)
        end
    end
end

# run_srvr(JuliaWebAPI.JSONMsgFormat(), JuliaWebAPI.ZMQTransport(SRVR_ADDR, ZMQ.REP, true), false)
run_httprpcsrvr(JuliaWebAPI.JSONMsgFormat(), JuliaWebAPI.ZMQTransport(SRVR_ADDR, ZMQ.REP, true), false)
