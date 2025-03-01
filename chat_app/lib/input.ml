let rec get_valid_port () =
  Printf.printf "Enter the port number (Empty for default port %d): \n" Constants.default_port;
  let input = read_line () in
  match input with
  | "" -> Constants.default_port
  | input -> 
        (try 
            let port = int_of_string input in
            if port > 0 && port <= 65535 then port
            else raise (Failure "Invalid range")
        with _ -> 
            Printf.printf "Invalid input. Please enter a valid port (1-65535).\n";
            get_valid_port ())

let is_valid_ipv4 ip =
    match Ipaddr.V4.of_string ip with
    | Ok _ -> true
    | Error _ -> false
    
let rec get_valid_ip_address () =
  Printf.printf "Enter the IP address or hostname of the server: \n";
  let input = read_line () in
  if is_valid_ipv4 input then 
    input
  else
    try 
      let host = Unix.gethostbyname input in
      Unix.string_of_inet_addr host.h_addr_list.(0)
    with Not_found ->
      Printf.printf "Invalid IP address/hostname. Please enter a valid IP address or hostname.\n";
      get_valid_ip_address ()