let parse_args () =
    let rec find_mode args =
        match args with
        | [] -> None
        | "s" :: _ | "server" :: _ -> Some "server"
        | "c" :: _ | "client" :: _ -> Some "client"
        | _ :: rest -> find_mode rest
    in
    find_mode (Array.to_list Sys.argv)

let rec prompt_mode () =
    match String.lowercase_ascii (read_line ()) with
    | "server" | "s" -> Chat_app.Server.init ()
    | "client" | "c" -> Chat_app.Client.init ()
    | _ ->
        Printf.printf "Invalid mode. Please enter 'Server' or 'Client'.\n";
        prompt_mode ()

let start () =
    match parse_args () with
    | Some "server" -> Chat_app.Server.init ()
    | Some "client" -> Chat_app.Client.init ()
    | _ ->
        Printf.printf "Enter application mode (Server/Client): \n";
        prompt_mode ()

let () = start ()