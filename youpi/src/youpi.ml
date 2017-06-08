open OUnit

open BlacsTypes

type requestType = Write | Read | Time | Hash

let args = List.tl (Array.to_list Sys.argv)

let apiUrl = List.hd args

let sheetName = "noname"

let httpHeader = ["accept: application/json"; "content: application/json"]

let makeUrl api typ getArgs =
  let separator = "/" in
  let func =
    (function Write -> (separator ^"write")
            | Read -> (separator ^"read")
            | Time -> (separator ^"time")
            | Hash -> "") typ in
  apiUrl ^
    func ^ separator ^ sheetName

let postFields name typ =
  let filename =
    match typ with
      Read  -> "requests/read/"  ^ name ^ ".json"
    | Write -> "requests/write/" ^ name ^ ".json"
    | _ -> assert false in
  let in_c = open_in filename in
  let s = input_line in_c in
  close_in in_c;
  s
  
let httpConnection url writeFunction httpHeader =
  let open Curl in
  let connection = init () in
  set_url connection url;
  set_writefunction connection writeFunction;
  set_httpheader connection httpHeader;
  connection

let postConnection url writeFunction httpHeader typ name =
  let open Curl in
  let connection = httpConnection url writeFunction httpHeader in
  set_post connection true;
  set_postfields connection (postFields name typ);
  connection


let getConnection url writeFunction httpHeader typ name =
  let open Curl in
  let connection = httpConnection (url^name) writeFunction httpHeader in
  connection

let makeConnection typ url writeFunction httpHeader name =
  match typ with
    Write | Read ->
    postConnection url writeFunction httpHeader typ name
  | Time ->
    getConnection url writeFunction httpHeader typ ""
  | Hash ->
    getConnection url writeFunction httpHeader typ ("/"^name)

let performConnection connection =
  let open Curl in
  perform connection;
  let rc = get_responsecode connection in
  cleanup connection;
  rc

let expectedResponse name =
  function
    Write -> Yojson.Safe.from_file ("requests/write/" ^ name ^ "-response.json") 
  | Read  -> Yojson.Safe.from_file ("requests/read/"  ^ name ^ "-response.json")
  | Time ->  Yojson.Safe.from_file ("requests/time/"  ^ name ^ "-response.json")
  | _ -> assert false

let testConnection typ name bufSize  =
  let url    = makeUrl apiUrl typ sheetName         in
  let buffer = Buffer.create bufSize                in
  let write  = fun data ->
    Buffer.add_string buffer data;
    String.length data                              in
  let connection =
    makeConnection typ url write httpHeader name          in
  try
    let responseCode = performConnection connection in
    print_endline (string_of_int responseCode); flush_all ();
    assert (responseCode = 200);
    Buffer.contents buffer 
  with _ -> assert false

let testResponse typ name responseReal =
  assert (responseReal = (expectedResponse name typ))

let makeTest typ name checkResponse bufSize =
  let response = testConnection typ name bufSize in
  if checkResponse then
    testResponse typ name (Yojson.Safe.from_string response)
  else
    assert true

let readTest name =
  let readPromise =
    match (Yojson.Safe.from_string (testConnection Read name 512)
           |> BlacsTypes.ReadPromise.of_yojson) with
      Result.Ok(rp) -> rp
    | _ -> assert false
  in
  (if readPromise.date > (Unix.gettimeofday ()) then
     Unix.sleepf (readPromise.date -. (Unix.gettimeofday ()))
   else ());
  let response = testConnection Hash readPromise.hash 1024 in
  print_endline (Yojson.Safe.(to_string (from_string response)));
  print_endline (Yojson.Safe.to_string (expectedResponse "simple" Read)); flush_all ();
  testResponse Read name (Yojson.Safe.from_string response)
    
    
let writeTest        = makeTest Write

let timeTest         = makeTest Time

let writeSimple ()   = writeTest "simple" false 1

let readSimple ()    = readTest "simple"

let timeSimple ()    = timeTest "simple" false 8
    
let suite = "blacs-api" >::: ["read_simple"  >:: readSimple;
                              "write_simple" >:: writeSimple;
                              "time_simple"  >:: timeSimple ]
                             
let _  = run_test_tt ~verbose:true suite
