# Chat App

## Overview

The **Chat App** is a simple one-on-one messaging application designed for communication between a server and a client over a network. The app operates in two modes:

1. **Server Mode**: The server waits for a client to establish a connection.
2. **Client Mode**: The client connects to the server by providing the server's IP address or hostname.

Once a connection is established, both the server and client can exchange messages. The receiving side automatically acknowledges every incoming message with a "Message received" notification, while the sender calculates and displays the round-trip time (RTT) for the acknowledgment.

The server can handle multiple client connections sequentially. After a client disconnects, the server continues to wait for the next client.

### Installation

To run the chat application, you need to have `opam` (OCaml's package manager) installed. You can find the installation instructions [here](https://ocaml.org/docs/installing-ocaml).

1. If you haven't already, create an opam switch for the project, preferably using version 5.3.0:  
   ```bash
   opam switch create <switch_name> 5.3.0
   ```  

2. Verify that the new switch is selected and activate it:  
   ```bash
   # Change to the newly created switch
   opam switch <switch_name>
   # Verify that the new switch has been selected
   opam switch list
   ```  

3. Import the required switch configuration to install the necessary packages:  
   ```bash
   opam switch import switch.export
   ```

### Usage

The chat app can be run in either **server** mode or **client** mode.

#### Running as a Server

To start the application in **server mode**, use the following command:

```bash
$ opam exec -- dune exec chat_app server
```

The server will wait for a client to connect.

#### Running as a Client

To run the application in **client mode**, use the following command:

```bash
$ opam exec -- dune exec chat_app client
```

The application will prompt you for the server information to connect to. Once connected, you can start sending messages.

### How It Works

1. **Server Mode**:
   - The server listens for incoming client connections on a specified port.
   - Upon receiving a connection from a client, the server enters communication mode, allowing message exchange.
   - The server acknowledges each received message and calculates the round-trip time (RTT) for the acknowledgment.

2. **Client Mode**:
   - The client connects to the server by providing the server's IP address and port.
   - After establishing the connection, the client can send messages to the server.
   - The client receives an acknowledgment for each sent message and calculates the round-trip time.

3. **Message Flow**:
   - Both the server and the client send and receive messages in a continuous loop.
   - Each message received is acknowledged by the other side with a message indicating the receipt (e.g., `"Message Received: <timestamp>"`).
   - The sender calculates the round-trip time (RTT) for every message after receiving the acknowledgment.

### Example Interaction

#### Server (Running in Server Mode):

```bash
$ opam exec -- dune exec chat_app server
Enter the port number (Empty for default port 12345): 

Starting server on port 12345
Press Ctrl+C to stop the server
Server started on port 12345
Client (127.0.0.1) connected
Received message: Client to Server Message
Server to Client Message
====================
Acknowledgment received for message sent at 2025-03-01 16:56:18
RTT: 0.747130 seconds
====================
```

#### Client (Running in Client Mode):

```bash
$ opam exec -- dune exec chat_app client
Starting client
Press Ctrl+C to stop the client
Enter the IP address or hostname of the server:
127.0.0.1
Enter the port number (Empty for default port 12345): 

Connecting to 127.0.0.1 on port 12345
Successfully connected to server
Client to Server Message
====================
Acknowledgment received for message sent at 2025-03-01 16:56:10
RTT: 0.138610 seconds
====================
Received message: Server to Client Message
```

### Terminating the Connection (Server)

- The **server** can terminate the connection at any time by exiting the application.
- Once the server disconnects, the application will prompt the user in client mode to connect to a new IP address and port.

### Terminating the Connection (Client)

- The **client** can disconnect at any time by exiting the application.
- Once the client disconnects, the **server** will continue to run and wait for the next client connection.

### Error Handling

- If the connection is lost or reset, the application will display an error message. In client mode, the application will prompt the user for a new IP address and port.
- The server will continue running and be ready for the next client connection.