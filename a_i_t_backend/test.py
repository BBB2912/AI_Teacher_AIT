import websockets
import asyncio
import json

async def test_ws():
    uri = "ws://127.0.0.1:8000/ws/messages?uid=hbskjdhdfhsdkjfskdbvfkjdhjdfh&teacher=biology"
    async with websockets.connect(uri) as websocket:
        while True:
            data = await websocket.recv()
            print("Received:", json.loads(data))

asyncio.run(test_ws())
