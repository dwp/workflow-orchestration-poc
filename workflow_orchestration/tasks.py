from datetime import datetime
import uuid
import json
import aws


class Task:

    def __init__(self, task_args: dict = {}) -> None:
        self.task_id: str = str(uuid.uuid1())
        self.time_submitted: str = datetime.now()
        self.time_finished: str
        self.state: str = "Submitted"
        self.arguments: dict = task_args

    def start(self) -> None:
        raise NotImplementedError
    
    def finish(self) -> None:
        self.time_finished = datetime.now()
        self.state = "Finished"


class EMRLauncher(Task):

    def __init__(self, task_args: dict):
        super().__init__(task_args)
        self.launcher_lambda = self.arguments['launch_lambda']

    def start(self) -> dict:
        print(f'Payload: {self.arguments}')
        del self.arguments['launch_lambda']
        resp = aws.invoke_lambda(self.launcher_lambda, json.dumps(self.arguments))
        r = json.loads(resp['Payload'].read().decode('utf-8'))
        return {
            "ClusterId": r['JobFlowId'],
            "ClusterArn": r['ClusterArn']
        }
