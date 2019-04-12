require 'aws-sdk-rekognition'
require 'aws-sdk-s3'
require_relative 'rate_dogs_table'

S3 = Aws::S3::Client.new
REKOGNITION = Aws::Rekognition::Client.new

def obj_upload(event:,context:)
  event['Records'].each do |record|
    md = record['s3']
    if md
      bucket = md['bucket']['name']
      key = md['object']['key']
      puts "Bucket: #{bucket} Key: #{key}"
      if valid_dog_image?(bucket, key)
        item = RateDogsTable.new(
          object_id: key,
          created_at: Time.now,
          rating: 0.0,
          vote_count: 0
        )
        item.save!
      else
        S3.delete_object(
          bucket: bucket,
          key: key
        )
      end
    end
  end
end

def obj_deleted(event:,context:)
  event['Records'].each do |record|
    md = record['s3']
    if md
      bucket = md['bucket']['name']
      key = md['object']['key']
      puts "Bucket: #{bucket} Key: #{key}"
      item = RateDogsTable.find(object_id: key)
      if item
        puts "Deleting #{key} from table."
        item.delete!
      else
        puts "No object_id for #{key} found in table."
      end
    end
  end
end

def valid_dog_image?(bucket, key)
  resp = REKOGNITION.detect_labels(
    image: {
      s3_object: {
        bucket: bucket,
        name: key
      }
    },
    min_confidence: 90
  )
  resp.labels.map { |l| l.name }.include?("Dog")
end
