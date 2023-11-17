import logging

LOGGER = logging.getLogger()
LOGGER.setLevel(logging.INFO)

def handler(event, context):
    LOGGER.info("Workflow Orchestrator Task Recorder Invoked!")
    print(event)