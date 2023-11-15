import json
from dataclasses import dataclass
from inspect import signature


class UnsupportedEventType(Exception):
	
	def __init__(self, event_type):
		self.event_type = event_type
		self.message = f"Event type {event_type} is not supported."
		super().__init__(self.message)


def filter_event_from_kwargs(**kwargs):
	event_type = kwargs.get("detail-type", None)
	cls = parse_event_type(event_type)
	
	cls_fields = {field for field in signature(cls).parameters}

	def populate_cls_fields(cls_fields, args, native_args={}):
		for name, val in args:
			if name in cls_fields or name == "detail":
				if isinstance(val, dict):
					populate_cls_fields(cls_fields, val.items(), native_args)
				else:
					native_args[name] = val
		return native_args

	native_args = populate_cls_fields(cls_fields, kwargs.items())
	native_args["event_type"] = cls.__name__

	return cls(**native_args)


def parse_event_type(event_type: str):
	supported_event_types = {
		"EMR Cluster State Change": EMRClusterEvent,
		"EMR Step Status Change": EMRStepEvent
	}
	event_class = supported_event_types.get(event_type, None)
	if event_class is None:
		raise UnsupportedEventType(event_type)
	return event_class


class EventEncoder(json.JSONEncoder):

	def default(self, o):
		return o.__dict__


@dataclass
class Event:
	id: str
	event_type: str
	region: str
	account: str
	time: str
	resources: list

	def to_json(self):
		return json.dumps(self, cls=EventEncoder)

	def uid(self):
		return self.id

	def group_id(self):
		raise NotImplementedError


@dataclass
class EMRClusterEvent(Event):
	name: str
	severity: str
	clusterId: str
	state: str
	message: str

	def group_id(self):
		return self.clusterId


@dataclass
class EMRStepEvent(Event):
	name: str
	severity: str
	clusterId: str
	stepId: str
	state: str
	message: str

	def group_id(self):
		return self.stepId