from tasks import Task, EMRLauncher


def task_constructor(task_name: str, task_args: dict = {}) -> Task:

    supported_tasks = {
        "emr_launcher": EMRLauncher
    }

    return supported_tasks[task_name](task_args)
