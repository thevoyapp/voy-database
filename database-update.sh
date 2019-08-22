source ~/.awslib
set -e
version=v1.0.0
name=database-interaction
filename=database-lambda/main
ctxfilename=main

GOOS=linux go build $filename.go
zip handler.zip $ctxfilename
rm $ctxfilename
awslib s3upload --as-type=cfn handler.zip lambda/$name/$version
rm handler.zip
awslib deploy-lambda \
  --sg-id sg-0b4c9d1b9761266a9 \
  --subnet-id subnet-0b097b5c1a3643b48 \
  --subnet-id subnet-0f682d6638e100118 \
  --no-version \
  $name \
  BaseApiRole \
  go1.x \
  $ctxfilename \
  lambda/$name/$version
