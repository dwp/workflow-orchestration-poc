from dynamo import get_table

class Task:

    def __init__(self, client, table_name):
        self.dynamo_client = client
        self.table = get_table(client, table_name)

    def create_task(
            self, 
            task_type, 
            task_id,
            correlation_id,
            state,
            task_info,
            time_submitted,
            time_updated,
            additional_infomation: str
        ):
        pass
    

    def get_task(self, task_type: str, task_id: str = None):
        pass

    def update_task(self, task_type, task_id):
        pass