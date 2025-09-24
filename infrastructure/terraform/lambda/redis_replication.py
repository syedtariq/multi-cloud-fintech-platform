import json
import redis
import os
import logging

logger = logging.getLogger()
logger.setLevel(logging.INFO)

def handler(event, context):
    """Redis replication from AWS ElastiCache to Azure Redis Cache"""
    
    try:
        # Environment variables
        aws_redis_endpoint = os.environ['AWS_REDIS_ENDPOINT']
        azure_redis_endpoint = os.environ['AZURE_REDIS_ENDPOINT']
        azure_redis_key = os.environ['AZURE_REDIS_KEY']
        
        # Connect to AWS ElastiCache Redis
        aws_redis = redis.Redis(
            host=aws_redis_endpoint,
            port=6379,
            decode_responses=True
        )
        
        # Connect to Azure Redis Cache
        azure_redis = redis.Redis(
            host=azure_redis_endpoint,
            port=6380,
            password=azure_redis_key,
            ssl=True,
            decode_responses=True
        )
        
        # Replicate critical data patterns
        patterns = ['session:*', 'cache:*', 'trading:*', 'market:*']
        total_keys = 0
        
        for pattern in patterns:
            keys = aws_redis.keys(pattern)
            pipe = azure_redis.pipeline()
            
            for key in keys:
                key_type = aws_redis.type(key)
                ttl = aws_redis.ttl(key)
                
                if key_type == 'string':
                    value = aws_redis.get(key)
                    pipe.set(key, value)
                    if ttl > 0:
                        pipe.expire(key, ttl)
                elif key_type == 'hash':
                    hash_data = aws_redis.hgetall(key)
                    pipe.hmset(key, hash_data)
                    if ttl > 0:
                        pipe.expire(key, ttl)
                
                total_keys += 1
            
            pipe.execute()
        
        return {
            'statusCode': 200,
            'body': json.dumps({
                'message': 'Redis replication completed',
                'keys_replicated': total_keys
            })
        }
        
    except Exception as e:
        logger.error(f"Redis replication failed: {str(e)}")
        return {
            'statusCode': 500,
            'body': json.dumps({'error': str(e)})
        }