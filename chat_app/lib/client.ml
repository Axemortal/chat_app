open Lwt.Infix

let resolve_host host_ip port =
  Lwt_unix.getaddrinfo host_ip (string_of_int port) [Unix.(AI_FAMILY PF_INET)] >>= function
  | [] -> Lwt.fail_with "Failed to resolve host"
  | addr :: _ -> Lwt.return addr.Unix.ai_addr

let connect_to_server_with_timeout socket sockaddr timeout =
  let timeout_task = Lwt_unix.sleep timeout >>= fun () -> Lwt.fail Exceptions.Connection_timeout in
  let connect_task = Lwt_unix.connect socket sockaddr in
  Lwt.pick [connect_task; timeout_task]

let connect_to_server server_socket =
  let input = Lwt_io.of_fd ~mode:Lwt_io.input server_socket in
  let output = Lwt_io.of_fd ~mode:Lwt_io.output server_socket in

  Lwt.finalize
    (fun () ->
      Lwt.catch
        (fun () -> Communication.handle_communication input output)
        (fun exn ->
          match exn with
          | Unix.Unix_error (Unix.ECONNRESET, _, _) ->
              Printf.printf "Server connection reset. Exiting...\n%!";
              Lwt.return_unit
          | _ ->
              Printf.printf "Unhandled exception: %s\n%!" (Printexc.to_string exn);
              Lwt.return_unit))
    (fun () -> Communication.close_connection server_socket input output)

let rec start_client timeout =
  let ip_address = Input.get_valid_ip_address () in
  let port = Input.get_valid_port () in

  Printf.printf "Connecting to %s on port %d\n%!" ip_address port;

  resolve_host ip_address port >>= fun sockaddr ->
  let socket = Lwt_unix.socket Unix.PF_INET Unix.SOCK_STREAM 0 in

  Lwt.catch
  (fun () -> 
    connect_to_server_with_timeout socket sockaddr timeout >>= fun () ->
    Printf.printf "Successfully connected to server\n%!";
    connect_to_server socket >>= fun () ->
    start_client timeout)
  (fun exn -> 
    match exn with
    | Exceptions.Connection_timeout ->
        Printf.printf "Connection attempt timed out. Restarting...\n%!";
        start_client timeout
    | _ -> 
        Printf.printf "Unhandled exception: %s\n%!" (Printexc.to_string exn);
        Lwt.return_unit)

let init () =
  Printf.printf "Starting client\n";
  Printf.printf "Press Ctrl+C to stop the client\n";
  let timeout = 5.0 in
  Lwt_main.run (start_client timeout)