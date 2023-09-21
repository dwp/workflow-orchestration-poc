import testutils
import requests
import time
from unittest import TestCase


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

    # def test_that_workflow_orchestrator_returns_correct_message(self):
        # payload = testutils.invoke_function_and_get_message('workflow_orchestrator')
        # self.assertEqual(payload['message'], 'Hello World!')

    def test_that_api_gateway_invokes_workflow_orchestrator(self):
        # TODO: ERR is in testutils when it attempts to read the response from workflow orchestrator after calling emr launcher
        resp = requests.post('http://workflow.localhost:4566/submit/emr_launcher')
        print(resp.content)
