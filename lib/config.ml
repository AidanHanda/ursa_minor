open! Core

module Provider = struct
  type t = Cloudflare of Cloudflare.t [@@deriving sexp]
end

type t = Provider.t list [@@deriving sexp]

let of_file filename = Sexp.load_sexp_conv_exn filename t_of_sexp
