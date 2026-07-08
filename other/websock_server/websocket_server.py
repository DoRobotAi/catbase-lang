# ws_simple.py - 简化的 WebSocket 服务器
import socket
import threading

def handle_client(client_socket):
    # 读取握手请求
    request = client_socket.recv(4096).decode()
    print("Received handshake request")
    
    # 检查是否是 WebSocket 升级请求
    if "Upgrade: websocket" not in request:
        client_socket.close()
        return
    
    # 生成握手响应
    import base64
    import hashlib
    import re
    
    key_match = re.search(r'Sec-WebSocket-Key: ([^\s]+)', request)
    if not key_match:
        client_socket.close()
        return
    
    key = key_match.group(1)
    magic = "258EAFA5-E914-47DA-95CA-C5AB0DC85B11"
    accept = base64.b64encode(hashlib.sha1((key + magic).encode()).digest()).decode()
    
    response = "HTTP/1.1 101 Switching Protocols\r\n"
    response += "Upgrade: websocket\r\n"
    response += "Connection: Upgrade\r\n"
    response += f"Sec-WebSocket-Accept: {accept}\r\n"
    response += "\r\n"
    
    client_socket.send(response.encode())
    print("Sent handshake response")
    
    # 接收数据帧
    try:
        while True:
            data = client_socket.recv(1024)
            if not data:
                break
            
            # 解析 WebSocket 帧
            fin = (data[0] >> 7) & 1
            opcode = data[0] & 0x0F
            masked = (data[1] >> 7) & 1
            payload_len = data[1] & 0x7F
            
            print(f"Received frame: fin={fin}, opcode={opcode}, masked={masked}, payload_len={payload_len}")
            
            if opcode == 0x8:  # Close frame
                print("Received close frame")
                break
            
            # 读取 mask key 和 payload
            idx = 2
            if payload_len == 126:
                payload_len = int.from_bytes(data[2:4], 'big')
                idx = 4
            elif payload_len == 127:
                payload_len = int.from_bytes(data[2:10], 'big')
                idx = 10
            
            mask_key = data[idx:idx+4] if masked else None
            payload_start = idx + (4 if masked else 0)
            payload = data[payload_start:payload_start + payload_len]
            
            # Unmask
            if masked and mask_key:
                payload = bytes([payload[i] ^ mask_key[i % 4] for i in range(len(payload))])
            
            message = payload.decode()
            print(f"Received message: {message}")
            
            # 发送响应 (echo)
            response = f"echo: {message}"
            response_bytes = response.encode()
            
            # 构建响应帧 (server -> client, 不需要 mask)
            frame = bytearray()
            frame.append(0x81)  # FIN + text opcode
            if len(response_bytes) < 126:
                frame.append(len(response_bytes))
            else:
                frame.append(126)
                frame.extend(len(response_bytes).to_bytes(2, 'big'))
            
            frame.extend(response_bytes)
            
            client_socket.send(frame)
            print(f"Sent response: {response}")
            
    except Exception as e:
        print(f"Error: {e}")
    finally:
        client_socket.close()
        print("Client disconnected")

# 创建服务器 socket
server = socket.socket(socket.AF_INET, socket.SOCK_STREAM)
server.setsockopt(socket.SOL_SOCKET, socket.SO_REUSEADDR, 1)
server.bind(('0.0.0.0', 28080))
server.listen(5)

print("WebSocket server started on port 28080")

while True:
    client, addr = server.accept()
    print(f"Accepted connection from {addr}")
    client_thread = threading.Thread(target=handle_client, args=(client,))
    client_thread.start()
