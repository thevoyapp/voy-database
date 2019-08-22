source ~/.awslib
set -e
version=v1.0.0
name=manual-database-task
filename=run

GOOS=linux go build $filename.go
zip handler.zip $filename
rm $filename
awslib s3upload --as-type=cfn handler.zip lambda/$name/$version
rm handler.zip
awslib deploy-lambda \
  --no-version \
  --env "USERNAME=`awslib import-value -e ssm /prod/database/username`" \
  --enc-env "PASSWORD=`awslib import-value -e ssm /prod/database/password`" \
  --env "HOST=`awslib import-value -e ssm /prod/database/host`" \
  --env "PORT=`awslib import-value -e ssm /prod/database/port`" \
  --time-out 20 \
  $name \
  BaseApiRole \
  go1.x \
  $filename \
  lambda/$name/$version
