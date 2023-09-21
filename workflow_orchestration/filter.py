from tasks import EMRLauncher


def task_constructor(task_name: str, task_args: dict = {}):

    supported_tasks = {
        "emr_launcher": EMRLauncher
    }

    return supported_tasks[task_name](task_args)