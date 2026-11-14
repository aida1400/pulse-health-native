import os
import sys
import threading
import time
import socket
from http.server import HTTPServer, SimpleHTTPRequestHandler
import asyncio
from playwright.async_api import async_playwright

WEB_DIR = os.path.join(os.path.dirname(os.path.abspath(__file__)), 'web')
PORT = 8080

class PulseHandler(SimpleHTTPRequestHandler):
    def __init__(self, *args, **kwargs):
        super().__init__(*args, directory=WEB_DIR, **kwargs)

    def log_message(self, format, *args):
        pass # suppress console noise

def start_server():
    server = HTTPServer(('0.0.0.0', PORT), PulseHandler)
    server.serve_forever()

def get_local_ip():
    try:
        s = socket.socket(socket.AF_INET, socket.SOCK_DGRAM)
        s.connect(('8.8.8.8', 80))
        ip = s.getsockname()[0]
        s.close()
        return ip
    except Exception:
        return '127.0.0.1'

async def launch_chrome_playwright(url):
    chrome_path = r"C:\Program Files\Google\Chrome\Application\chrome.exe"
    async with async_playwright() as p:
        print("[1/3] در حال راه‌اندازی مرورگر کروم با پلی‌رایت...")
        browser = await p.chromium.launch(
            executable_path=chrome_path,
            headless=False,
            args=[
                "--app=" + url,
                "--window-size=440,900",
                "--disable-infobars"
            ]
        )
        page = await browser.new_page()
        await page.goto(url)
        print(f"[2/3] سامانه پالس با موفقیت روی صفحه شما باز شد!")
        print(f"[3/3] لینک دسترسی پارتنر و نصب مستقیم روی گوشی:")
        local_ip = get_local_ip()
        print(f"      👉 http://{local_ip}:{PORT}")
        print("\nبرنامه در حال اجراست. جهت بستن، کلید Ctrl+C را فشار دهید.")

        while True:
            await asyncio.sleep(1)

if __name__ == '__main__':
    t = threading.Thread(target=start_server, daemon=True)
    t.start()
    time.sleep(0.5)

    local_url = f"http://localhost:{PORT}"
    try:
        asyncio.run(launch_chrome_playwright(local_url))
    except KeyboardInterrupt:
        print("\nسامانه پالس متوقف شد.")
