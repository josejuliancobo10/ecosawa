$code = @"
using System;
using System.Net;
using System.IO;
public class Server {
    public static void Start() {
        HttpListener listener = new HttpListener();
        listener.Prefixes.Add("http://localhost:8080/");
        listener.Start();
        Console.WriteLine("Listening on http://localhost:8080/");
        while (true) {
            HttpListenerContext context = listener.GetContext();
            HttpListenerRequest request = context.Request;
            HttpListenerResponse response = context.Response;
            string rawPath = request.Url.LocalPath.TrimStart('/');
            if(rawPath == "") rawPath = "code.html"; 
            string path = Path.Combine(Environment.CurrentDirectory, rawPath);
            if (File.Exists(path)) {
                byte[] buffer = File.ReadAllBytes(path);
                response.ContentLength64 = buffer.Length;
                
                string ext = Path.GetExtension(path).ToLower();
                if(ext == ".html") response.ContentType = "text/html";
                else if(ext == ".png") response.ContentType = "image/png";
                else if(ext == ".css") response.ContentType = "text/css";
                else if(ext == ".js") response.ContentType = "application/javascript";
                
                Stream output = response.OutputStream;
                output.Write(buffer, 0, buffer.Length);
                output.Close();
            } else {
                response.StatusCode = 404;
                response.Close();
            }
        }
    }
}
"@
Add-Type -TypeDefinition $code
[Server]::Start()
