#!/usr/bin/env python
import pika
import time

connection = pika.BlockingConnection(pika.ConnectionParameters(
        host='localhost'))
channel = connection.channel()

channel.queue_declare(queue='facebook3')

for i in range(1,7):

	body_value = "Message from Pangea account name -- facebook3 -- # !" + str(i)

	channel.basic_publish(exchange='', routing_key='facebook3', body=body_value )

	print " [x] Sent 'Message from Pangea account name  -- facebook3 -- #'"  + str(i)

	time.sleep(1)

connection.close()
