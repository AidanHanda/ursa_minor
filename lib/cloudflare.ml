open! Core
open Async
open Jsonaf.Export

type t =
  { apikey : string
  ; zone : string
  ; url : string
  }
[@@deriving sexp]

module Zone_info = struct
  type t =
    { id : string
    ; name : string
    }
  [@@deriving sexp, jsonaf] [@@jsonaf.allow_extra_fields]
end

module Dns_record = struct
  type t =
    { id : string
    ; name : string
    ; content : string
    ; proxied : bool
    ; tags : string list
    ; type_ : string [@key "type"]
    }
  [@@deriving sexp, jsonaf] [@@jsonaf.allow_extra_fields]
end

module Patched_dns_record = struct
  type t =
    { name : string
    ; content : string
    ; proxied : bool
    ; tags : string list
    ; type_ : string [@key "type"]
    ; comment : string
    ; ttl : int
    }
  [@@deriving sexp, jsonaf]

  let with_changed_ip ?(comment = "Set with Ursa_minor") (dns_record : Dns_record.t) ~ip =
    { name = dns_record.name
    ; content = ip
    ; proxied = dns_record.proxied
    ; tags = dns_record.tags
    ; type_ = dns_record.type_
    ; comment
    ; ttl = 1 (* 1 is automatic *)
    }
  ;;
end

module Json_result = struct
  type t = { success : bool } [@@deriving sexp, jsonaf] [@@jsonaf.allow_extra_fields]
end

let build_headers t =
  let headers =
    Cohttp.Header.add (Cohttp.Header.init ()) "Content-Type" "application/json"
  in
  let headers =
    Cohttp.Header.add headers "Authorization" [%string "Bearer %{t.apikey}"]
  in
  headers
;;

let get_zone_info t =
  let cloudflare_endpoint = Uri.of_string "https://api.cloudflare.com/client/v4/zones" in
  let headers = build_headers t in
  let%bind _, body = Cohttp_async.Client.get ~headers cloudflare_endpoint in
  let%map content = Cohttp_async.Body.to_string body in
  let result = Jsonaf.of_string content in
  match result with
  | `Object x ->
    let _, results = List.find_exn x ~f:(fun (k, _) -> String.equal k "result") in
    List.map (Jsonaf.list_exn results) ~f:Zone_info.t_of_jsonaf
  | _ -> raise_s [%message [%here] "Unable to build zone infos" (result : Jsonaf.t)]
;;

let get_dns_records t ~(zone_info : Zone_info.t) =
  let cloudflare_endpoint =
    Uri.of_string
      [%string "https://api.cloudflare.com/client/v4/zones/%{zone_info.id}/dns_records"]
  in
  let headers = build_headers t in
  let%bind _, body = Cohttp_async.Client.get ~headers cloudflare_endpoint in
  let%map content = Cohttp_async.Body.to_string body in
  let json = Jsonaf.of_string content in
  let _, result =
    Jsonaf.assoc_list_exn json
    |> List.filter ~f:(fun (k, _) -> String.equal k "result")
    |> List.hd_exn
  in
  Jsonaf.list_exn result |> List.map ~f:Dns_record.t_of_jsonaf
;;

let update t ~ip =
  let%bind zone_infos = get_zone_info t in
  let zone_info =
    zone_infos
    |> List.filter ~f:(fun (z : Zone_info.t) -> String.equal t.zone z.name)
    |> List.hd_exn
  in
  let%bind dns_records = get_dns_records t ~zone_info in
  let dns_record =
    dns_records
    |> List.filter ~f:(fun (d : Dns_record.t) -> String.equal d.name t.url)
    |> List.hd_exn
  in
  let cloudflare_endpoint =
    Uri.of_string
      [%string
        "https://api.cloudflare.com/client/v4/zones/%{zone_info.id}/dns_records/%{dns_record.id}"]
  in
  let patched_record = Patched_dns_record.with_changed_ip dns_record ~ip in
  let body =
    Patched_dns_record.jsonaf_of_t patched_record
    |> Jsonaf.to_string
    |> Cohttp_async.Body.of_string
  in
  let headers = build_headers t in
  let%bind _, body = Cohttp_async.Client.patch ~headers ~body cloudflare_endpoint in
  let%map content = Cohttp_async.Body.to_string body >>| Jsonaf.of_string in
  let json_result = Json_result.t_of_jsonaf content in
  if json_result.success
  then Or_error.return ()
  else
    Or_error.error_s [%message "Could not patch" (patched_record : Patched_dns_record.t)]
;;
