open Lwt.Infix

let get_client_address client_socket =
  try
    match Unix.getpeername (Lwt_unix.unix_file_descr client_socket) with
    | Unix.ADDR_INET (addr, _) -> Unix.string_of_inet_addr addr
    | _ -> "Unknown"
  with Unix.Unix_error _ -> "Unknown"

let rec accept_connections server_socket =
  Lwt_unix.accept server_socket >>= fun (client_socket, _) ->

    Printf.printf "Client (%s) connected\n%!" (get_client_address client_socket);

    let input = Lwt_io.of_fd ~mode:Lwt_io.input client_socket in
    let output = Lwt_io.of_fd ~mode:Lwt_io.output client_socket in
    
    Lwt.finalize
      (fun () ->
        Lwt.catch
          (fun () -> Communication.handle_communication input output)
          (fun exn ->
            match exn with
            | Unix.Unix_error (Unix.ECONNRESET, _, _) ->
                Printf.printf "Client connection reset. Waiting for new clients...\n%!";
                Lwt.return_unit
            | _ ->
                Printf.printf "Unhandled exception: %s\n%!" (Printexc.to_string exn);
                Lwt.return_unit))
      (fun () -> Communication.close_connection client_socket input output) >>= fun () ->

    accept_connections server_socket

let start_server port =
  let sockaddr = Unix.(ADDR_INET (inet_addr_any, port)) in
  let server_socket = Lwt_unix.socket Unix.PF_INET Unix.SOCK_STREAM 0 in
  Lwt_unix.setsockopt server_socket Unix.SO_REUSEADDR true;
  Lwt_unix.bind server_socket sockaddr >>= fun () ->
  Lwt_unix.listen server_socket 1;
  Lwt_io.printlf "Server started on port %d" port >>= fun () ->
  accept_connections server_socket

let init () =
  let port = Input.get_valid_port () in
  Printf.printf "Starting server on port %d\n" port;
  Printf.printf "Press Ctrl+C to stop the server\n%!";
  Lwt_main.run (start_server port)