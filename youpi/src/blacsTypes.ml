module Value =
struct

  open Yojson.Safe
  open Ppx_deriving_yojson_runtime
         
  type tylabel =
      TyInt
    | TyNone
    | TyCount 

  let tylabel_to_yojson =
    let f s = `String s in
    function
      TyInt   -> f "int"
    | TyCount -> f "count"
    | TyNone  -> f "none"

  let tylabel_of_yojson =
    function
      `String "int"   -> Result.Ok(TyInt)
    | `String "count" -> Result.Ok(TyCount)
    | `String "none"  -> Result.Ok(TyNone)
    | _ -> Result.Error("tylabel")

  type promise = {date:float; domain:int list; value: int option} [@@deriving yojson]

  type t =
    {ty:tylabel; data:int list; promises: promise list} [@@deriving yojson]

  let int i =  {ty = TyInt; data = [i]; promises = []}

  let count r1 c1 r2 c2 v = {ty = TyCount; data=[r1;c1;r2;c2;v];promises=[]}

  let none = {ty= TyNone; data=[]; promises=[]}

  let string_of_value = function
      {ty = TyInt   ; data = [i]} -> "val "^ (string_of_int i)
    | {ty = TyCount ; data = [r1;c1;r2;c2;v]} ->
      let soi = string_of_int in
      "=#(" ^ soi r1 ^ ", " ^ soi c1 ^ ", " ^ soi r2 ^
      ", " ^ soi c2  ^ ", " ^ soi v  ^ ")"
    | {ty = TyNone  ; data =_}  -> "⊥"
    | _ -> assert false

  let json_string_of_value = fun
    v -> to_yojson v |> Yojson.Safe.to_string 
end
module Coordinates =
struct
  type t = {row:int; col:int} [@@ deriving yojson]

  let coords r c = {row=r; col=c}
end

module ReadPromise =
struct
  type t = {date:float; hash:string}[@@deriving yojson]
end

type locatedValue = {coords: Coordinates.t; value: Value.t} [@@deriving yojson]

type locatedValueList = locatedValue list [@@deriving yojson]

let locValue r c v =
  let c = Coordinates.coords r c in
  {coords=c; value=v}
