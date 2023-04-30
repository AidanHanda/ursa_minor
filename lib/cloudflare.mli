open! Core
open Async

type t =
  { apikey : string
  ; zone : string
  ; url : string
  }
[@@deriving sexp]

val update : t -> ip:string -> unit Deferred.Or_error.t
