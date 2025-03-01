open Lwt.Infix

let handle_communication input_channel output_channel =
  let rec receive_loop () =
    Lwt_io.read_line_opt input_channel >>= function
    | Some msg when String.starts_with ~prefix:"Message Received: " msg ->
      (try
        (* Extract timestamp from the acknowledgment *)
        let time_str, _ = String.split_on_char ':' (String.sub msg 17 (String.length msg - 17)) |> List.hd, List.tl in
        let time_sent = float_of_string time_str in
        let time_received = Unix.gettimeofday () in
        Printf.printf "Acknowledgment received for message sent at %f. RTT: %.6f seconds\n%!" time_sent (time_received -. time_sent)
      with _ ->
        Printf.printf "Malformed acknowledgment: %s\n%!" msg);
      receive_loop ()
    | Some msg ->
        Printf.printf "Received: %s\n%!" msg;
        (* Extract timestamp to include in the acknowledgment *)
        let time_sent = String.split_on_char ':' msg |> List.hd in
        Lwt_io.write_line output_channel ("Message Received: " ^ time_sent) >>= receive_loop
    | None -> 
        Printf.printf "Client disconnected.\n%!";
        Lwt.return_unit
  in

  let rec send_loop () =
    Lwt_io.read_line_opt Lwt_io.stdin >>= function
    | Some msg ->
        let time_sent = Unix.gettimeofday () |> string_of_float in
        let msg_with_time = time_sent ^ ":" ^ msg in
        Lwt_io.write_line output_channel msg_with_time >>= send_loop
    | None -> 
        Printf.printf "Input closed. Stopping communication.\n%!";
        Lwt.return_unit
  in

  Lwt.join [receive_loop (); send_loop ()]


let close_connection socket input output =
  Lwt.catch
    (fun () ->
      Unix.shutdown (Lwt_unix.unix_file_descr socket) Unix.SHUTDOWN_ALL;
      Lwt_io.close input >>= fun () ->
      Lwt_io.close output >>= fun () ->
      Lwt_unix.close socket >>= fun () ->
      Lwt.return_unit)
    (fun exn ->
      match exn with
      | _ -> Lwt.return_unit)