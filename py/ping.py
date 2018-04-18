import socket

UDP_IP = "127.0.0.1"
LISTENING_PORT = 64304
PR_PORT = 64305

sock = socket.socket(socket.AF_INET, socket.SOCK_STREAM)
sock.bind((UDP_IP, LISTENING_PORT))
sock.listen(1)

while True:
    conn, addr = sock.accept()
    print ('Connection Accepted')
    while 1:
        data = conn.recv(4)
        print ('Data received.')
        if not data: 
            print('No data available?')
            break
        print ("received data: %s" % data.decode('utf-8'))
        conn.send(b'pong')  # echo
    conn.close()