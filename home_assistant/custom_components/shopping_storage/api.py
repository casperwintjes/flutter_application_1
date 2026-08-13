import json
from homeassistant.components.http import HomeAssistantView
from homeassistant.const import CONF_API_PASSWORD

from .const import DATA_FILE
from .storage import read_storage, write_storage


class ShoppingStorageView(HomeAssistantView):
    url = "/api/shopping_storage"
    name = "shopping_storage"

    async def get(self, request):
        return self.json(read_storage(DATA_FILE))

    async def post(self, request):
        payload = await request.json()
        write_storage(payload, DATA_FILE)
        return self.json(payload)


async def async_setup_api(hass):
    hass.http.register_view(ShoppingStorageView)
