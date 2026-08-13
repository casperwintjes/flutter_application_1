from .api import async_setup_api

async def async_setup(hass, config):
    await async_setup_api(hass)
    return True
