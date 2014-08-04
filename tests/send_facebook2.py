#!/usr/bin/env python
import pika
import time

connection = pika.BlockingConnection(pika.ConnectionParameters(
        host='localhost'))
channel = connection.channel()

channel.queue_declare(queue='facebook2')

for i in range(1,6):

	body_value = "Message from Pangea account name -- facebook2 -- # !" + str(i)

	channel.basic_publish(exchange='', routing_key='facebook2', body=body_value )

	print " [x] Sent 'Message from Pangea account name -- facebook2 -- #'"  + str(i)

	time.sleep(1)

connection.close()
