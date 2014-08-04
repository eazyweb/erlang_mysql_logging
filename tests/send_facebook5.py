#!/usr/bin/env python
import pika
import time

connection = pika.BlockingConnection(pika.ConnectionParameters(
        host='localhost'))
channel = connection.channel()

channel.queue_declare(queue='facebook5')

for i in range(1,9):

	body_value = "Message from Pangea account name -- facebook5 -- # !" + str(i)

	channel.basic_publish(exchange='', routing_key='facebook5', body=body_value )

	print " [x] Sent 'Message from Pangea account name -- facebook5 -- #'"  + str(i)

	time.sleep(1)

connection.close()
