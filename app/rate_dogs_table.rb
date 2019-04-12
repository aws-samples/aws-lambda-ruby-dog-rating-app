require 'aws-record'
require_relative 'smart_query_shim'
require 'aws-sdk-s3'

BUCKET = Aws::S3::Bucket.new(ENV["BucketName"])

class RateDogsTable
  include Aws::Record
  set_table_name ENV["TableName"]
  string_attr :object_id, hash_key: true
  epoch_time_attr :created_at
  float_attr :rating
  integer_attr :vote_count

  def image_url
    BUCKET.object(self.object_id).public_url
  end

  def score
    if rating < 10.0
      10.0
    else
      (rating * 10).to_i.to_f / 10
    end
  end

  def self.rate(id, user_rating)
    user_rating = user_rating.to_f
    return nil if user_rating < 10.0
    item = find(object_id: id)
    if item
      vc = item.vote_count
      rt = item.rating
      agg = (rt * vc.to_f) + user_rating
      vc += 1
      item.vote_count = vc
      item.rating = (agg / vc.to_f)
      item.save
    else
      nil
    end
  end
end
