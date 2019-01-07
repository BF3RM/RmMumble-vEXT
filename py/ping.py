import socket
import time 

UDP_IP = "127.0.0.1"
LISTENING_PORT = 64304
PR_PORT = 64305

sock = socket.socket(socket.AF_INET, socket.SOCK_STREAM)
sock.bind((UDP_IP, LISTENING_PORT))
sock.listen(1)

while True:
    conn, addr = sock.accept()
    print ('Connection Accepted')
    my_bytes = bytearray(64)
    my_bytes[0] = 123
    my_bytes[1:] = b'Ping'
    try:
        while 1:
            conn.send(my_bytes)
            print(my_bytes)
            time.sleep(0.5)
            continue
            data = conn.recv(10)
            if len(data) > 0:
                print ("received data: %s" % data.decode('utf-8'))
    except Exception as e:
        print ('connection broken %s' % e)
        pass
    conn.close()
