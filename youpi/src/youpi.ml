open BlacsTypes

type requestType = Write | Read | Time | Hash

exception ParseException of string

exception ConnectionException

exception TestException

let pi = acos (-. 1.)

let print str = print_string str; flush_all ()

(** Normal Gauss distribution **)
let g = fun mu sigma x ->
  let sigma2 = sigma ** 2. in
  (1.  /.  sigma *. sqrt( 2. *. pi) *. exp (-. ((x -. mu) ** 2. ) /. (2. *. sigma2)))

let benchFunction iterations f  =
  let rec aux i acc =
    match i with
    | 0 -> acc
    | _ ->
      try
        let time = f () in
        aux (i-1) (time::acc)
      with
        ConnectionException -> aux (i-1) acc
      | TestException       -> []
  in
  let timeList = aux iterations [] in
  let measures = float_of_int (List.length timeList) in
  let mu =
    (List.fold_left ( +. ) 0. timeList) /. measures in
  let sigma =
    (List.fold_left (fun x y  -> ((x -. mu) ** 2.) +. y) 0. timeList) /. measures in
  let g = g mu sigma in
  let normalDistribution = List.map (fun x -> (g x, x)) timeList in
  let max =
    List.fold_left
      (fun max x -> Pervasives.max max (Some (fst x))) None normalDistribution in
  match max with
    Some x -> List.assoc x normalDistribution
  | None -> (- 1.0)

 
let args = List.tl (Array.to_list Sys.argv)

let apiUrl = List.hd args

let implementation = match args with _::name::_ -> name | _-> assert false

(* let apiUrl = "https://virtserver.swaggerhub.com/blacs/pervasives/0.1" *)

let skip = fun _ -> ()

let sheetName = "noname"

let readDir dirname =
  let l = Array.to_list (Sys.readdir dirname) in
  List.filter (fun str -> ".rq" = Str.last_chars str 3) l 

let header = ["accept: application/json"; "content-type: application/json"]

let makeUrl api typ getArgs =
  let separator = "/" in
  let func =
    (function Write -> (separator ^"write")
            | Read ->  (separator ^"read")
            | Time ->  (separator ^"time")
            | Hash -> "") typ in
  apiUrl ^
    func ^ separator ^ sheetName

let httpConnection url writeFunction httpHeader =
  let open Curl in
  let connection = init () in
  set_url connection url;
  set_writefunction connection writeFunction;
  set_httpheader connection httpHeader;
  connection

let postConnection url writeFunction httpHeader typ httpBody name =
  let open Curl in
  let connection = httpConnection url writeFunction httpHeader in
  set_post connection true;
  set_postfields connection httpBody;
  connection


let getConnection url writeFunction httpHeader typ getParams =
  let open Curl in
  let urlParams =
    (function
      None -> url
    | Some params -> (url ^ "/" ^ params)) getParams in
  let connection = httpConnection urlParams writeFunction httpHeader in
  connection

let makeConnection typ url writeFunction httpHeader httpBody name =
  match typ,httpBody with
    Write,Some(body) | Read,Some(body) ->
    postConnection url writeFunction httpHeader typ body name
  | Time,None ->
    getConnection url writeFunction httpHeader typ None
  | Hash,None ->
    getConnection url writeFunction httpHeader typ (Some name)
  | _ -> assert false

let performConnection connection =
  let open Curl in
  perform connection;
  get_responsecode connection
let timeInServer connection =
  let open Curl in
  let connectTime      = get_connecttime connection       in
  let startTransferTime = get_starttransfertime connection in
  startTransferTime -. connectTime
  
let getHttpBody path =
  try
    let s = Yojson.Safe.from_file path |> Yojson.Safe.to_string in
    s
  with _ -> failwith "dldl"

let expectedResponse name typ =
  let len = String.length name in
  let name = Str.string_before name (len-3) in
  try
    let response = 
      match typ with
        Write -> Yojson.Safe.from_file ("requests/write/" ^ name ^ "-response.json") 
      | Read  -> Yojson.Safe.from_file ("requests/read/"  ^ name ^ "-response.json")
      | Time ->  Yojson.Safe.from_file ("requests/time/"  ^ name ^ "-response.json")                   
      | _ -> assert false in
    Some response
  with _ -> None

let testConnection typ name httpBody bufSize  =
  let url    = makeUrl apiUrl typ sheetName         in
  let buffer = Buffer.create bufSize                in
  let write  = fun data ->
    Buffer.add_string buffer data;
    String.length data                              in
  let connection =
    makeConnection typ url write header httpBody name          in
  try
    let responseCode = performConnection connection in
    let time         = timeInServer connection      in
    Curl.cleanup connection;
    assert(200 = responseCode);
    (Buffer.contents buffer,time)
  with _ ->  raise ConnectionException


let makeTest typ name expectedResponse httpBody bufSize () =
  let response,time = testConnection typ name httpBody bufSize in
  (match expectedResponse with
     Some (re) ->
     if (re =  (Yojson.Safe.from_string response))
     then () else raise TestException
  | None -> ());
  time

let writeTest = fun name ->
  let body = getHttpBody ("requests/write/"^name) in
  let expectedResponse = expectedResponse name Time in
  makeTest Write name expectedResponse (Some body) 1 
  

let readTest name  =
  let open ReadPromise in
  let body = getHttpBody ("requests/read/"^name) in
  let expectedResponse = expectedResponse name Read       in
  let readHash () =
    let readPromise =
      try
        match
          (Yojson.Safe.from_string (fst (testConnection Read name (Some body) 1024))
           |> of_yojson)
        with
          Result.Ok(rp) -> rp
        | _ -> raise (ParseException "Cannot parse ReadPromise")
      with
      | ConnectionException -> raise ConnectionException
    in
    let wait =
      (if readPromise.date > (Unix.gettimeofday ()) then
        let t = (readPromise.date -. (Unix.gettimeofday ()) +. 0.05) in
        Unix.sleepf t;
        t
      else 0.)
    in
    wait +. makeTest Hash readPromise.hash expectedResponse None 1024 ()
  in
  readHash
  
    
let timeTest         = fun name ->
  let expectedResponse = expectedResponse name Time in
  makeTest Time name expectedResponse None 128 


let writeRequests = readDir "requests/write"

let readRequests  = readDir "requests/read"

let timeRequests  = readDir "requests/time"

let run cmd =
  let status = Sys.command cmd in
  if status != 0 then
    print_endline (cmd ^ " failed with status " ^ (string_of_int status))

let evalTest () =
  let cmd =
    "docker run --rm --name evaluator evaluator http://172.17.0.2:8080 test alice bob"
  in
  let t0 = Unix.gettimeofday () in
  (for i=1 to 5 do
    run cmd;
  done);
  let t1 = Unix.gettimeofday () in
  (t1 -. t0) /. 5.

  

let makeBlacsTest typ name  =
  match typ with
    Write -> writeTest name
  | Read  ->  readTest name
  | Time  -> timeTest  name
  | _ -> assert false

let runBench = List.iter (fun x -> print (string_of_float (benchFunction 10 x)))

let () =
  let makeWriteTest = makeBlacsTest Write in
  let makeReadTest  = makeBlacsTest Read  in
  let makeTimeTest  = makeBlacsTest Time  in
  let writeTests    = List.map makeWriteTest writeRequests in
  let readTests     = List.map makeReadTest  readRequests  in
  let timeTests     = List.map makeTimeTest  timeRequests  in
  print implementation; print ", ";
  runBench writeTests;print ", ";
  runBench readTests; print ", ";
  runBench timeTests; print ", ";
  runBench [evalTest]
  
