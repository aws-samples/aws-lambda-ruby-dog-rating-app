require 'sinatra'
require_relative 'rate_dogs_table'
require 'aws-sdk-s3'

UPLOAD_BUCKET = Aws::S3::Resource.new.bucket(ENV["BucketName"])

get "/" do
  query = RateDogsTable.build_scan.limit(10).run! # reverse order?
  @dogs = query.page
  erb :index
end

get "/add" do
  uuid = "#{Time.now.to_i}_#{SecureRandom.uuid}"
  @presigned_post = UPLOAD_BUCKET.presigned_post(
    key: "#{uuid}",
    content_length_range: 1..2097152, # 2 MB Max
    success_action_redirect: "https://#{$baseHost}/Prod/",
    acl: 'public-read',
    metadata: {
      'original-filename' => '${filename}'
    }
  )
  erb :add
end

post "/rate/:id" do
  RateDogsTable.rate(params[:id], params[:rating])
  redirect "/Prod/"
end
