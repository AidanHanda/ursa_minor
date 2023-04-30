open! Core
open Async

let command () =
  let open Command.Let_syntax in
  Command.async_or_error
    ~summary:"Updates given urls to the public IP address of the current machine"
    [%map_open
      let config_file =
        flag
          "config"
          (required Filename_unix.arg_type)
          ~doc:"FILENAME config file to update urls from"
      in
      fun () ->
        let%bind.Deferred iplookup = Ursa_minor.Iplookup.get_ip () in
        Log.Global.info_s [%message "Using IP" (iplookup : Ursa_minor.Iplookup.t)];
        let config = Ursa_minor.Config.of_file config_file in
        List.map config ~f:(function
          | Ursa_minor.Config.Provider.Cloudflare (c : Ursa_minor.Cloudflare.t) ->
          Log.Global.info_s [%message "Updating" c.url];
          Ursa_minor.Cloudflare.update c ~ip:iplookup.ip)
        |> Deferred.Or_error.all_unit]
;;

let () = Command_unix.run (command ())
