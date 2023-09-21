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

    def test_that_api_gateway_invokes_workflow_orchestrator(self):
        # TODO: Assert we get back payload with Task ID
        resp = requests.post('http://workflow.localhost:4566/submit/emr_launcher')
        print(resp.content)
