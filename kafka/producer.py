#!/usr/bin/env python2.7
# -*- coding: utf-8 -*-

from pykafka import KafkaClient

def sync_kafka(topic):
	with topic.get_sync_producer() as producer:
		for i in range(4):
			producer.produce('test msg ' + str(i ** 2))

def async_kafka(topic):
	with topic.get_producer(delivery_reports=True) as producer:
		count = 0
		while True:
			count += 1
			producer.produce('test msg ' + str(count), partition_key='{}'.format(count))
			if count % 10**2 == 0:  # adjust this or bring lots of RAM ;)
				while True:
					try:
						msg, exc = producer.get_delivery_report(block=False)
						if exc is not None:
							print 'Failed to deliver msg {}: {}'.format(msg.partition_key, repr(exc))
						else:
							print 'Successfully delivered msg {}'.format(msg.partition_key)
					except Exception,ex:
						print 'ex' + str(ex)
						break

client = KafkaClient(hosts="192.168.10.88:9092")

topic = client.topics['kafka_test']

# produce to kafka synchronously
async_kafka(topic)

