open Lwt.Infix

let handle_communication input_channel output_channel =
  let format_time timestamp =
    let time = Unix.gmtime timestamp in
    Printf.sprintf "%04d-%02d-%02d %02d:%02d:%02d"
      (time.tm_year + 1900) (time.tm_mon + 1) time.tm_mday
      time.tm_hour time.tm_min time.tm_sec
  in

  let rec receive_loop () = 
    Lwt_io.read_line_opt input_channel >>= function
    | Some msg when String.starts_with ~prefix:"Message Received: " msg -> 
      (try
        let timestamp_str = String.sub msg 18 10 in
        let timestamp = float_of_string_opt timestamp_str in
        match timestamp with
        | Some ts ->
            Printf.printf "====================\n%!";
            Printf.printf "Acknowledgment received for message sent at %s\n%!" (format_time ts);
            let time_received = Unix.gettimeofday () in
            Printf.printf "RTT: %.6f seconds\n%!" (time_received -. ts);
            Printf.printf "====================\n%!";
        | None -> 
            Printf.printf "Malformed timestamp in acknowledgment: %s\n%!" timestamp_str
      with _ -> 
        Printf.printf "Malformed acknowledgment: %s\n%!" msg);
      receive_loop ()
    | Some msg -> 
        (match String.split_on_char ':' msg with
        | time_str :: rest -> 
            let message = String.concat ":" rest in
            Printf.printf "Received message: %s\n%!" message;
            Lwt_io.write_line output_channel ("Message Received: " ^ time_str) >>= receive_loop
        | _ ->
            Printf.printf "Malformed message: %s\n%!" msg;
            receive_loop ()
        )
    | None -> 
        Printf.printf "Session disconnected.\n%!"; 
        Lwt.return_unit
  in

  let rec send_loop () =
    Lwt_io.read_line_opt Lwt_io.stdin >>= function
    | Some msg -> 
        let time_sent_str = Unix.gettimeofday () |> string_of_float in
        let msg_with_time = time_sent_str ^ ":" ^ msg in
        Lwt_io.write_line output_channel msg_with_time >>= send_loop
    | None -> 
        Printf.printf "Input closed. Stopping communication.\n%!"; 
        Lwt.return_unit
  in

  Lwt.pick [receive_loop (); send_loop ()]

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