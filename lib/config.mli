open! Core

module Provider : sig
  type t = Cloudflare of Cloudflare.t [@@deriving sexp]
end

type t = Provider.t list [@@deriving sexp]

val of_file : Filename.t -> t
