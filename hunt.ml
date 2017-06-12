open Unix

let return = fun x -> Some x

let skip = fun _ -> ()

let run cmd =
  let status = Sys.command cmd in
  if status != 0 then
    print_endline (cmd ^ "failed with status" ^ (string_of_int status))
                             
let pullRepos () =
  run "mr up 2>&1 1>/dev/null"

let getRepoPath s =
  let open Str in
  let r = regexp "\\[\\(contrib/.+\\)\\]" in
  try
    let _ = search_forward r s 0 in
    Some (matched_group 1 s)
  with
    Not_found -> None

let lsRepos  () =
  let in_c = open_in ".mrconfig" in
  let readLine () =
    try return (input_line in_c)
    with _ -> None in
  let rec aux l =
    match readLine () with
    |None -> List.rev l
    |Some line -> match getRepoPath line with
        Some repo -> aux (repo :: l)
      | None  -> aux l
  in
  let l = aux [] in
  close_in in_c;
  l

let readLine command =
  let in_c = open_process_in command in
  try
    let line = input_line in_c in
    close_in in_c;
    line
  with
    _ -> ""

let contribs = Hashtbl.create 5

let hashOf contrib = fst (Hashtbl.find contribs contrib)

let subjectOf contrib = snd (Hashtbl.find contribs contrib)

let runGitAt command contrib  =
  "cd " ^ contrib ^ " && git " ^ command

let requestedBench contrib =
  let currentHash,currentSubject=
    let open Str in
    let s       = readLine (runGitAt "log --format=\"%H:%s\" -1" contrib)  in
    let r       = regexp "\\([a-f0-9]+\\):\\(.*\\)"                  in
    let ()      = skip (search_forward r s 0)                      in
    matched_group 1 s,matched_group 2 s
  in
  let updateContrib () = Hashtbl.replace contribs contrib (currentHash,currentSubject) in
  let shouldBench = try
      skip Str.(search_forward (regexp "bench") currentSubject 0);
      true
    with
      Not_found -> false
  in
  try
    let previousHash = hashOf contrib in
      updateContrib ();
      shouldBench && (previousHash != currentHash)
  with Not_found ->
      updateContrib ();
      shouldBench



let bench contrib =
  let contribName = List.nth Str.(split (regexp "/") contrib) 1 in
  run ("./check " ^ contribName)

let rec loop () = Unix.(
    let open List in
    pullRepos ();
    skip (iter bench (filter requestedBench (lsRepos ())));
    run "./updateReport.sh";
    Unix.sleep 1800;
    loop ()
  )

let main = loop ()
