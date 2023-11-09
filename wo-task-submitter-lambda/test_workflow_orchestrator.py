import testutils
import requests
import uuid
import json
from unittest import TestCase
from filter import task_constructor
from tasks import Task, EMRLauncher
from handler import parse_request_path


class TestParsePathTestCase(TestCase):

    def test_parse_path_with_sumit_emr_launcher(self):
        path = "/submit/emr_launcher"
        command, task_name, extra_args = parse_request_path(path)
        self.assertEqual(command, "submit")
        self.assertEqual(task_name, "emr_launcher")
        self.assertIsNone(extra_args)


class TestLambdaInvoke(TestCase):
    
    @classmethod
    def setUpClass(cls):
        print('\r\nSetting up the class')
        testutils.create_lambda('workflow_orchestrator')
        testutils.wait_for_function('workflow_orchestrator')
        cls.task_args = {
            'launch_lambda': 'emr-launcher',
            'overrides': {
                'Name': 'local-cluster'
            }
        }

    @classmethod
    def tearDownClass(cls):
        print('\r\nTearing down the class')
        testutils.delete_lambda('workflow_orchestrator')

    def test_that_api_gateway_invokes_workflow_orchestrator(self):
        resp = requests.post('http://workflow.localhost:4566/submit/emr_launcher', json=self.task_args)
        task_response = json.loads(resp.text)
        self.assertTrue(uuid.UUID(task_response.get('task_id')))

    # def test_that_workflow_orchestrator_lambda_invokes(self):
    #     # For some reason this test only work when ran standalone.
    #     resp = testutils.invoke_function_and_get_message('workflow_orchestrator')
    #     self.assertTrue(uuid.UUID(resp))



class TestTask(TestCase):

    def setUp(self):
        self.task = Task()

    def test_task_has_id(self):
        task_id = self.task.task_id
        self.assertIsNotNone(task_id)
    
    def test_task_has_start_time(self):
        task_start_time = self.task.time_submitted
        self.assertIsNotNone(task_start_time)

    def test_task_has_initial_state(self):
        task_state = self.task.state
        self.assertEquals(task_state, "Submitted")


class TestEMRLauncher(TestCase):

    def setUp(self):
        task_args = {
            'launch_lambda': 'emr-launcher',
            'overrides': {
                'Name': 'local-cluster'
            }
        }
        self.task = task_constructor('emr_launcher', task_args)
        

    def test_task_filter_with_emr_launcher(self):
        assert type(self.task) is EMRLauncher
