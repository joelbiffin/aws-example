import logging
import os


logger = logging.getLogger()
logger.setLevel(logging.INFO)


def handler(event, context):
  logger.info('## ENVIRONMENT VARIABLES')
  logger.info(os.environ)

  logger.info('## EVENT')
  logger.info(event)

  logger.info('## CONTEXT')
  logger.info(context)

  return {
    'statusCode': 200,
    'body': "Hello, World!"
  }
