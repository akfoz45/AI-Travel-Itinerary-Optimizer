import json
from channels.generic.websocket import AsyncWebsocketConsumer

class TripConsumer(AsyncWebsocketConsumer):
    async def connect(self):
        self.trip_id = self.scope["url_route"]["kwargs"]["trip_id"]
        self.room_group_name = f"trip_{self.trip_id}"

        await self.channel_layer.group_add(
            self.room_group_name,
            self.channel_name
        )
        await self.accept()

    async def disconnect(self, close_code):
        await self.channel_layer.group_discard(
            self.room_group_name,
            self.channel_name
        )

    async def receive(self, text_data):
        data = json.loads(text_data)
        action = data.get("action")

        await self.channel_layer.group_send(
            self.room_group_name,
            {
                "type": "trip_update",
                "action": action
            }
        )

    async def trip_update(self, event):
        action = event['action']

        await self.send(text_data=json.dumps({
            'action': action
        }))