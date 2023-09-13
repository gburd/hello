#include <stdio.h>
#include <stdlib.h>
#include <unistd.h>
#include <sys/socket.h>
#include <netinet/in.h>

int echo() {
  int listen_socket, client_socket;
  struct sockaddr_in listen_addr, client_addr;
  socklen_t client_addr_len;
  char buffer[1024];
  int bytes_received;

  // Create a socket
  listen_socket = socket(AF_INET, SOCK_STREAM, 0);
  if (listen_socket < 0) {
    perror("socket");
    exit(1);
  }

  // Bind the socket to port 5001
  listen_addr.sin_family = AF_INET;
  listen_addr.sin_port = htons(5001);
  listen_addr.sin_addr.s_addr = INADDR_ANY;
  if (bind(listen_socket, (struct sockaddr *)&listen_addr, sizeof(listen_addr)) < 0) {
    perror("bind");
    exit(1);
  }

  // Listen for connections
  listen(listen_socket, 5);

  // Accept a connection
  client_addr_len = sizeof(client_addr);
  client_socket = accept(listen_socket, (struct sockaddr *)&client_addr, &client_addr_len);
  if (client_socket < 0) {
    perror("accept");
    exit(1);
  }

  // Echo the data back to the client
  while (1) {
    bytes_received = recv(client_socket, buffer, sizeof(buffer), 0);
    if (bytes_received < 0) {
      perror("recv");
      exit(1);
    }

    if (bytes_received == 0) {
      // The client has closed the connection
      break;
    }

    send(client_socket, buffer, bytes_received, 0);
  }

  // Close the sockets
  close(listen_socket);
  close(client_socket);

  return 0;
}

int main() {
  while (1) {
    echo();
  }
  return 0;
}
