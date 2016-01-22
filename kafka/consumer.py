#!/usr/bin/env python2.7
# -*- coding: utf-8 -*-

from pykafka import KafkaClient
from time import sleep

import logging
logging.basicConfig()

def kafka_balance(topic):
	consumer = topic.get_balanced_consumer(
		consumer_group='testgroup',
		auto_commit_enable=True,  # 设置为Flase的时候不需要添加 consumer_group
		zookeeper_connect='192.168.10.88:2181' # 这里就是连接多个zk
	)
	for message in consumer:
		if message is not None:
			print('key: %s %s value: %s' % (message.partition_id, message.offset, message.value))
			sleep(1)

def kafka_simple(topic):
	consumer = topic.get_simple_consumer()
	for message in consumer:
		if message is not None:
			print message.offset, message.value

def kafka_simple2(topic):
	consumer = topic.get_simple_consumer(consumer_group='testgroup', auto_commit_enable=True, reset_offset_on_start=True)
	for message in consumer:
		if message is not None:
			print message.offset, message.value



client = KafkaClient(hosts="192.168.10.88:9092")

topic = client.topics['kafka_test']

kafka_balance(topic)
