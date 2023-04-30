open! Core
open Async

type t = { ip : string } [@@deriving sexp, jsonaf]

val get_ip : unit -> t Deferred.t
