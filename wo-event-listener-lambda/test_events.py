import unittest
import json

import time
import testutils
from events import (
    UnsupportedEventType,
    EventEncoder,
    EMRClusterEvent,
    EMRStepEvent,
    filter_event_from_kwargs
)

class TestEMRClusterEventTestCase(unittest.TestCase):

    def setUp(self) -> None:
        self.test_event = """{
            "version": "0",
            "id": "8535abb0-f87e-4640-b7b6-8de000dfc30a",
            "detail-type": "EMR Cluster State Change",
            "source": "aws.emr",
            "account": "123456789012",
            "time": "2016-12-16T21:00:23Z",
            "region": "us-east-1",
            "resources": [],
            "detail": {
                "severity": "INFO",
                "stateChangeReason": "{\\"code\\":\\"USER_REQUEST\\",\\"message\\":\\"Terminated by user request\\"}",
                "name": "Development Cluster",
                "clusterId": "j-1YONHTCP3YZKC",
                "state": "TERMINATED",
                "message": "Amazon EMR Cluster j-1YONHTCP3YZKC (Development Cluster) has terminated at 2016-12-16 21:00 UTC with a reason of USER_REQUEST."
            }
        }"""
        json_object = json.loads(self.test_event)
        self.event = filter_event_from_kwargs(**json_object)

    def test_event_filter_to_event_object(self):
        self.assertIsNotNone(self.event.account)
        self.assertIsNotNone(self.event.region)
        self.assertIsNotNone(self.event.resources)
        self.assertIsNotNone(self.event.time)
        self.assertEqual(self.event.id, "8535abb0-f87e-4640-b7b6-8de000dfc30a")
        self.assertEqual(self.event.severity, "INFO")
        self.assertEqual(self.event.name, "Development Cluster")
        self.assertEqual(self.event.clusterId, "j-1YONHTCP3YZKC")
        self.assertEqual(self.event.state, "TERMINATED")


    def test_event_filter_is_event_type(self):
        self.assertIsInstance(self.event, EMRClusterEvent)

    def test_event_json_dumps(self):
        print(self.event.to_json())

    def test_event_uid(self):
        self.assertEqual(self.event.uid(), "8535abb0-f87e-4640-b7b6-8de000dfc30a")

    def test_event_group_id(self):
        self.assertEqual(self.event.group_id(), "j-1YONHTCP3YZKC")


class TestEMRStepEventTestCase(unittest.TestCase):

    def setUp(self) -> None:
        self.test_event = """{
            "version": "0",
            "id": "6965277f-1f52-4564-9f7b-ae90b0ce2294",
            "detail-type": "EMR Step Status Change",
            "source": "aws.emr",
            "account": "123456789012",
            "time": "2016-12-16T20:53:09Z",
            "region": "us-east-1",
            "resources": [],
            "detail": {
                "severity": "ERROR",
                "actionOnFailure": "CONTINUE",
                "stepId": "s-36ZWOFMZ19IUZ",
                "name": "CustomJAR",
                "clusterId": "j-1YONHTCP3YZKC",
                "state": "FAILED",
                "message": "Step s-36ZWOFMZ19IUZ (CustomJAR) in Amazon EMR cluster j-1YONHTCP3YZKC (Development Cluster) failed at 2016-12-16 20:53 UTC."
            }
        }"""
        json_object = json.loads(self.test_event)
        self.event = filter_event_from_kwargs(**json_object)

    def test_event_filter_to_event_object(self):
        self.assertIsNotNone(self.event.account)
        self.assertIsNotNone(self.event.region)
        self.assertIsNotNone(self.event.resources)
        self.assertIsNotNone(self.event.time)
        self.assertEqual(self.event.id, "6965277f-1f52-4564-9f7b-ae90b0ce2294")
        self.assertEqual(self.event.severity, "ERROR")
        self.assertEqual(self.event.name, "CustomJAR")
        self.assertEqual(self.event.clusterId, "j-1YONHTCP3YZKC")
        self.assertEqual(self.event.stepId, "s-36ZWOFMZ19IUZ")
        self.assertEqual(self.event.state, "FAILED")


    def test_event_filter_is_event_type(self):
        self.assertIsInstance(self.event, EMRStepEvent)

    def test_event_json_dumps(self):
        print(self.event.to_json())

    def test_event_group_id(self):
        self.assertEqual(self.event.group_id(), "s-36ZWOFMZ19IUZ")

    def test_event_uid(self):
        self.assertEqual(self.event.uid(), "6965277f-1f52-4564-9f7b-ae90b0ce2294")


class TestUnsupportedEventTestCase(unittest.TestCase):

    def setUp(self) -> None:
        self.test_event = """{
            "version": "0",
            "id": "8535abb0-f87e-4640-b7b6-8de000dfc30a",
            "detail-type": "Some Random Event Type Description",
            "source": "aws.emr",
            "account": "123456789012",
            "time": "2016-12-16T21:00:23Z",
            "region": "us-east-1",
            "resources": [],
            "detail": {
                "severity": "INFO",
                "stateChangeReason": "{\\"code\\":\\"USER_REQUEST\\",\\"message\\":\\"Terminated by user request\\"}",
                "name": "Development Cluster",
                "clusterId": "j-1YONHTCP3YZKC",
                "state": "TERMINATED",
                "message": "Amazon EMR Cluster j-1YONHTCP3YZKC (Development Cluster) has terminated at 2016-12-16 21:00 UTC with a reason of USER_REQUEST."
            }
        }"""

    def test_event_filter_to_event_object_raises_unsupported_event_type(self):
        with self.assertRaises(UnsupportedEventType):
            json_object = json.loads(self.test_event)
            filter_event_from_kwargs(**json_object)
