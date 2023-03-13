# AWS Cloud Intelligence Dashboard for Azure Glue Script - CloudFormation - Microsoft EA
# Parameters fetched from System Manager Parameter Store
import boto3
ssm_client = boto3.client('ssm')
var_source_path = ((ssm_client.get_parameter(Name="cidazure-var_source_path"))["Parameter"]["Value"])
var_destination_path = ((ssm_client.get_parameter(Name="cidazure-var_destination_path"))["Parameter"]["Value"])
var_processed_path = ((ssm_client.get_parameter(Name="cidazure-var_processed_path"))['Parameter']['Value'])
var_glue_database = ((ssm_client.get_parameter(Name="cidazure-var_glue_database"))['Parameter']['Value'])
var_glue_table = ((ssm_client.get_parameter(Name="cidazure-var_glue_table"))['Parameter']['Value'])
var_bucketname = ((ssm_client.get_parameter(Name="cidazure-var_bucketname"))['Parameter']['Value'])
var_source = ((ssm_client.get_parameter(Name="cidazure-var_source"))['Parameter']['Value'])
var_target = ((ssm_client.get_parameter(Name="cidazure-var_target"))['Parameter']['Value'])
SELECTED_TAGS = ((ssm_client.get_parameter(Name="cidazure-var_azuretags"))['Parameter']['Value']).split(", ")

# Glue base
import sys
from awsglue.transforms import *
from awsglue.utils import getResolvedOptions
from pyspark.context import SparkContext
from awsglue.context import GlueContext
from awsglue.job import Job

sc = SparkContext.getOrCreate()
glueContext = GlueContext(sc)
spark = glueContext.spark_session

# Read CSV files, raising exception and stopping script gracefully if folder is empty
import os
try:
    df1 = spark.read.option("header","true").option("delimiter",",").option("escape", "\"").csv(var_source_path)
except Exception as e:
    print("Can not import files from {}, folder rather empty or other issue occurred".format(var_source_path))
    print("Exception message: {}".format(e))
    os._exit(0)

# Create column Tags_map (transformed Tags column as map)
# TODO: Drop columns Tags and Tags_map as not needed further
from pyspark.sql.functions import col, udf
from pyspark.sql.types import ArrayType, StringType, MapType
import json
def transform_to_map(resource_tags):
    if resource_tags: return dict(json.loads("{" + resource_tags + "}"))
    return ""

tagsTransformToMapUDF = udf(lambda x:transform_to_map(x), MapType(StringType(), StringType()))
df1 = df1.withColumn("Tags_map", tagsTransformToMapUDF(col("Tags")))

# Create columns per selected tag with sufficient values
for tag in SELECTED_TAGS:
    df1 = df1.withColumn("tag-"+tag, df1.Tags_map.getItem(tag))

# Parse date columns and cast non string datatypes
from pyspark.sql.functions import to_date
from pyspark.sql.functions import col
from pyspark.sql.types import *

df2 = df1.withColumn("DateParsed",to_date(df1.Date, "MM/dd/yyyy")) \
         .withColumn("BillingPeriodStartDateParsed",to_date(df1.BillingPeriodStartDate, "MM/dd/yyyy")) \
         .withColumn("BillingPeriodEndDateParsed",to_date(df1.BillingPeriodEndDate, "MM/dd/yyyy")) \
         .withColumn("BillingProfileId",col("BillingProfileId").cast(LongType())) \
         .withColumn("Cost",col("Cost").cast(DecimalType(21,16))) \
         .withColumn("EffectivePrice",col("EffectivePrice").cast(DecimalType(21,16))) \
         .withColumn("IsAzureCreditEligible",col("IsAzureCreditEligible").cast(BooleanType())) \
         .withColumn("PayGPrice",col("PayGPrice").cast(LongType())) \
         .withColumn("Quantity",col("Quantity").cast(DoubleType())) \
         .withColumn("UnitPrice",col("UnitPrice").cast(DoubleType())) \

# Create partition column
from pyspark.sql.functions import trunc
df2 = df2.withColumn("Month", trunc(df2.DateParsed, "MM"))

# Create parquet files and update glue catalog
from awsglue.dynamicframe import DynamicFrame
dyf3 = DynamicFrame.fromDF(df2, glueContext, "dyf3")
sink = glueContext.getSink(
    connection_type="s3",
    path=(var_destination_path),
    enableUpdateCatalog=True,
    partitionKeys=["Month"])
sink.setFormat("glueparquet")
sink.setCatalogInfo(catalogDatabase=(var_glue_database), catalogTableName=(var_glue_table))
sink.writeFrame(dyf3)

# Move CSV files to processed folder
import boto3
for obj in boto3.resource('s3').Bucket(var_bucketname).objects.filter(Prefix=var_source):
    source_filename = (obj.key).split('/')[-1]
    copy_source = {
        'Bucket': var_bucketname,
        'Key': obj.key
    }
    boto3.resource('s3').meta.client.copy(copy_source, var_bucketname, f"{var_target}/{source_filename}")
    boto3.resource('s3').Object(var_bucketname, obj.key).delete()

# Sample Tests
# print(processedfiles)
# df2.select('Date','DateParsed','BillingPeriodStartDate','BillingPeriodStartDateParsed','BillingPeriodEndDate','BillingPeriodEndDateParsed','Month','ResourceId','AdditionalInfo').show(10)
# df2.printSchema()

# Reconciliation check
# from pyspark.sql.functions import sum as sum
# df2.select(sum(df2.CostInBillingCurrency)).show()

