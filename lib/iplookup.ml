open! Core
open Async
open Jsonaf.Export

type t = { ip : string } [@@deriving sexp, jsonaf]

let get_ip () =
  let api_uri = "https://ipv4.seeip.org/jsonip" |> Uri.of_string in
  let%bind _, body = Cohttp_async.Client.get api_uri in
  let%map body_string = Cohttp_async.Body.to_string body in
  Jsonaf.of_string body_string |> t_of_jsonaf
;;
