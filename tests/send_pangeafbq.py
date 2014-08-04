#!/usr/bin/env python
import pika
import time

connection = pika.BlockingConnection(pika.ConnectionParameters(
        host='localhost'))
channel = connection.channel()

channel.queue_declare(queue='pangeafbq')

for i in range(1,10):

	body_value = "Message from Pangea # !" + str(i)

	channel.basic_publish(exchange='', routing_key='pangeafbq', body=body_value )

	print " [x] Sent 'Message from Pangea #'"  + str(i)

	time.sleep(1)

connection.close()
