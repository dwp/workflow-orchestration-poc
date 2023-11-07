from tasks import Task


class TaskSubmitter:

    def __init__(self, task: Task) -> None:
        self.task = task

    def submit(self) -> dict:
        resp = self.task.start()
        return {
            "task_id": self.task.task_id,
            "task_detail": resp
        }