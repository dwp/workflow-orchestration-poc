import testutils
import requests
from unittest import TestCase
import filter
from tasks import EMRLauncher

class TestInvoke(TestCase):
    
    @classmethod
    def setUpClass(cls):
        print('\r\nSetting up the class')
        testutils.create_lambda('workflow_orchestrator')
        testutils.wait_for_function('workflow_orchestrator')

    @classmethod
    def tearDownClass(cls):
        print('\r\nTearing down the class')
        testutils.delete_lambda('workflow_orchestrator')

    def test_that_api_gateway_invokes_workflow_orchestrator(self):
        # TODO: Assert we get back payload with Task ID
        resp = requests.post('http://workflow.localhost:4566/submit/emr_launcher')
        print(resp.content)

    def test_task_filter_with_emr_launcher(self):
        task_args = {
            'launch_lambda': 'emr-launcher',
            'overrides': {
                'Name': 'local-cluster'
            }
        }
        task = filter.task_constructor('emr_launcher', task_args)
        assert self.assertTrue(isinstance(task, EMRLauncher))
