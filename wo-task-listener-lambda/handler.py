import logging
import json
from events import filter_event_from_kwargs

LOGGER = logging.getLogger()
LOGGER.setLevel(logging.INFO)

def handler(event, context):
    LOGGER.info('Workflow Orchestrator Task Listener Invoked!')
    event = filter_event_from_kwargs(**json.loads(event))
    