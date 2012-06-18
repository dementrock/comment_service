require 'rubygems'
require 'yajl'
require 'active_record'
require 'sinatra'

require_relative 'models/comment'
require_relative 'models/comment_thread'

env_index = ARGV.index("-e")
env_arg = ARGV[env_index + 1] if env_index
env = env_arg || ENV["SINATRA_ENV"] || "development"
databases = YAML.load_file("config/database.yml")
ActiveRecord::Base.establish_connection(databases[env])

class String
  def is_i?
    self.to_i.to_s == self
  end
end

# retrive all comments of a commentable object
get '/api/v1/:commentable_type/:commentable_id/comments' do |commentable_type, commentable_id|
  if not commentable_id.is_i?
    error 400, {:error => "commentable_id must be an integer"}.to_json
  else
    comment_thread = CommentThread.find_or_create_by_commentable_type_and_commentable_id(commentable_type, commentable_id)
    comment_thread.json_comments
  end
end

# create a new top-level comment
post '/api/v1/:commentable_type/:commentable_id/comments' do |commentable_type, commentable_id|
  if not commentable_id.is_i?
    error 400, {:error => "commentable_id must be an integer"}.to_json
  else
    comment_thread = CommentThread.find_or_create_by_commentable_type_and_commentable_id(commentable_type, commentable_id)
    comment_params = params.select {|key, value| %w{body title user_id course_id}.include? key}
    comment = comment_thread.super_comment.children.create(comment_params)
    if comment.valid?
      comment.to_json
    else
      error 400, comment.errors.to_json
    end
  end
end

# create a new subcomment (reply to comment) only if the comment is NOT a super comment
post '/api/v1/comment/:comment_id' do |comment_id|
  if not comment_id.is_i?
    error 400, {:error => "comment_id must be integers"}.to_json
  else
    comment = Comment.find_by_id(comment_id)
    if comment.nil? or not comment.comment_thread.nil?
      error 400, {:error => "invalid comment id"}.to_json
    else
      comment_params = params.select {|key, value| %w{body title user_id course_id}.include? key}
      sub_comment = comment.children.create(comment_params)
      if comment.valid?
        comment.to_json
      else
        error 400, comment.errors.to_json
      end
    end
  end
end
