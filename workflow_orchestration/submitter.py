from tasks import Task


class TaskSubmitter:

    def __init__(self, task: Task) -> None:
        self.task = task

    def submit(self) -> str:
        resp = self.task.start()
        return self.task.task_id
