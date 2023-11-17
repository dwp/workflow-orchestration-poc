import logging

LOGGER = logging.getLogger()
LOGGER.setLevel(logging.INFO)


class NoTableFoundException(Exception):
    """Raised when no table is found by the client."""

def table_exists(client, table_name: str):
    try:
        return client.describe_table(TableName=table_name)
    except client.exceptions.ResourceNotFoundException as e:
        LOGGER.error(f"Dynamodb table with name '{table_name}' does not exist")
        return False
    except Exception as e:
        LOGGER.error(f"Unexpected error when describing table '{table_name}': {e}")
        return False


class DynamoTable:
    
    def __init__(self, client, table_name: str, primary_key: dict):
        self.client = client
        if table_exists(client, table_name):
            self.table_name = self.table_name 
        else:
            raise NoTableFoundException
        self.primary_key = primary_key

    def create_item(self, item):
        try:
            self.client.put_item(
                TableName=self.table_name,
                Item=item,
                ConditionExpression="attribute_not_exists(sk})"
            )
        except self.client.exceptions.ConditionalCheckFailedException as e:
            LOGGER.error(f"Item with Task Id already exists in table.")
        except Exception as e:
            LOGGER.error(f"Unexpected error occurred whilst putting an item into DynamoTable: '{e}'")

    def update_item(self, item):
        try:
            self.client.update_item(
                TableName=self.table_name,
                Key=
            )