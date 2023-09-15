#!/bin/bash

# Script to lookup CloudTrail events related to PutBucketPolicy and PutBucketAcl

REGION="us-west-2"
MAX_ITEMS=100

aws cloudtrail lookup-events \
--region $REGION \
--lookup-attributes AttributeKey=EventName,AttributeValue=PutBucketPolicy AttributeKey=EventName,AttributeValue=PutBucketAcl \
--max-items $MAX_ITEMS \
--query 'Events[*].{Time:EventTime, User:Username, Event:EventName, Request:requestParameters}' \
--output table