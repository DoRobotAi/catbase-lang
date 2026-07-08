#!/usr/bin/env python3
"""
简易HTTP POST请求接收服务器
用于测试POST客户端发送的数据
"""

import json
from http.server import HTTPServer, BaseHTTPRequestHandler
from urllib.parse import urlparse, parse_qs

class PostRequestHandler(BaseHTTPRequestHandler):
    """处理POST请求的Handler"""
    
    def do_POST(self):
        """处理POST请求"""
        try:
            # 获取Content-Length头
            content_length = int(self.headers.get('Content-Length', 0))
            
            # 读取请求体
            post_data = self.rfile.read(content_length)
            
            # 解析URL路径
            parsed_path = urlparse(self.path)
            
            # 打印请求信息
            print("\n" + "="*60)
            print(f"收到POST请求:")
            print(f"时间: {self.date_time_string()}")
            print(f"客户端地址: {self.client_address[0]}:{self.client_address[1]}")
            print(f"请求路径: {self.path}")
            print(f"Content-Type: {self.headers.get('Content-Type', '未指定')}")
            print(f"Content-Length: {content_length}")
            print("-"*60)
            
            # 尝试解析为JSON
            if post_data:
                try:
                    # 尝试解码为UTF-8字符串
                    data_str = post_data.decode('utf-8')
                    
                    # 尝试解析为JSON
                    try:
                        json_data = json.loads(data_str)
                        print("接收到的JSON数据:")
                        print(json.dumps(json_data, indent=2, ensure_ascii=False))
                    except json.JSONDecodeError:
                        # 如果不是JSON，检查是否是表单数据
                        if self.headers.get('Content-Type') == 'application/x-www-form-urlencoded':
                            form_data = parse_qs(data_str)
                            print("接收到的表单数据:")
                            for key, value in form_data.items():
                                print(f"  {key}: {value}")
                        else:
                            # 普通文本数据
                            print("接收到的原始数据:")
                            print(data_str)
                            
                except UnicodeDecodeError:
                    # 二进制数据
                    print("接收到二进制数据:")
                    print(f"Hex: {post_data.hex()}")
                    print(f"Bytes: {post_data}")
            else:
                print("请求体为空")
            
            print("="*60 + "\n")
            
            # 发送响应
            self.send_response(200)
            self.send_header('Content-Type', 'application/json')
            self.send_header('Access-Control-Allow-Origin', '*')  # 允许跨域
            self.end_headers()
            
            response = {
                "status": "success",
                "message": "POST请求已接收",
                "received_bytes": content_length
            }
            self.wfile.write(json.dumps(response).encode('utf-8'))
            
        except Exception as e:
            print(f"处理请求时发生错误: {e}")
            self.send_response(500)
            self.end_headers()
            error_msg = json.dumps({"error": str(e)})
            self.wfile.write(error_msg.encode('utf-8'))
    
    def do_GET(self):
        """处理GET请求，提供简单的说明页面"""
        self.send_response(200)
        self.send_header('Content-Type', 'text/html; charset=utf-8')
        self.end_headers()
        
        html = """
        <!DOCTYPE html>
        <html>
        <head>
            <meta charset="UTF-8">
            <title>POST测试服务器</title>
            <style>
                body { font-family: Arial, sans-serif; margin: 40px; }
                .container { max-width: 800px; margin: 0 auto; }
                h1 { color: #333; }
                .info { background: #f5f5f5; padding: 20px; border-radius: 5px; margin: 20px 0; }
                code { background: #eee; padding: 2px 5px; border-radius: 3px; }
                pre { background: #333; color: #fff; padding: 15px; border-radius: 5px; overflow-x: auto; }
            </style>
        </head>
        <body>
            <div class="container">
                <h1>POST测试服务器运行中</h1>
                <div class="info">
                    <p><strong>服务器状态:</strong> 正常运行中</p>
                    <p><strong>功能:</strong> 接收所有POST请求并打印内容</p>
                    <p><strong>使用方法:</strong> 向此地址发送POST请求即可</p>
                </div>
                
                <h2>测试示例:</h2>
                
                <h3>cURL命令:</h3>
                <pre>curl -X POST http://localhost:8000 \\
  -H "Content-Type: application/json" \\
  -d '{"name": "测试", "value": 123}'</pre>
                
                <h3>Python requests示例:</h3>
                <pre>import requests

data = {"name": "测试", "value": 123}
response = requests.post("http://localhost:8000", json=data)
print(response.json())</pre>
                
                <h3>发送表单数据:</h3>
                <pre>curl -X POST http://localhost:8000 \\
  -d "username=test&password=123456"</pre>
                
                <p><em>查看服务器控制台可看到接收到的数据详情</em></p>
            </div>
        </body>
        </html>
        """
        self.wfile.write(html.encode('utf-8'))
    
    def do_OPTIONS(self):
        """处理OPTIONS请求，支持CORS预检"""
        self.send_response(200)
        self.send_header('Access-Control-Allow-Origin', '*')
        self.send_header('Access-Control-Allow-Methods', 'POST, GET, OPTIONS')
        self.send_header('Access-Control-Allow-Headers', 'Content-Type')
        self.end_headers()
    
    def log_message(self, format, *args):
        """重写日志方法，使用标准输出"""
        pass  # 我们已经在do_POST中自定义了日志输出


def run_server(port=8000):
    """启动HTTP服务器"""
    server_address = ('', port)
    httpd = HTTPServer(server_address, PostRequestHandler)
    
    print(f"POST测试服务器已启动")
    print(f"监听地址: http://localhost:{port}")
    print(f"按 Ctrl+C 停止服务器")
    print("-"*60)
    
    try:
        httpd.serve_forever()
    except KeyboardInterrupt:
        print("\n服务器正在关闭...")
        httpd.server_close()
        print("服务器已停止")


if __name__ == '__main__':
    import sys
    
    # 可以通过命令行参数指定端口
    port = 8000
    if len(sys.argv) > 1:
        try:
            port = int(sys.argv[1])
        except ValueError:
            print(f"无效端口号: {sys.argv[1]}，使用默认端口 8000")
    
    run_server(port)