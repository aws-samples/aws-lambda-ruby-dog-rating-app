## AWS Lambda Ruby Dog Rating App

A sample serverless application running on Sinatra to rate dogs.

## Try it yourself!

To run this yourself, we build and deploy using the SAM CLI:

```
sam build
sam package --template-file .aws-sam/build/template.yaml --output-template-file packaged.yaml --s3-bucket BUCKETYOUOWN
sam deploy --template-file packaged.yaml --stack-name dog-rating-app --capabilities CAPABILITY_IAM --region APPREGION --parameter-overrides AppBucketName=MYUNIQUEBUCKETNAME
aws cloudformation describe-stacks --stack-name dog-rating-app 
```

## License Summary

This sample code is made available under a modified MIT license. See the LICENSE file.
