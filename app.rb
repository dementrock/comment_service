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

get '/api/v1/:commentable_type/:commentable_id/comments' do |commentable_type, commentable_id|
  if commentable_id.to_i.to_s != commentable_id
    error 400, {:error => "commentable_id must be an integer"}.to_json
  else
    comment_thread = CommentThread.find_or_create_by_commentable_type_and_commentable_id(commentable_type, commentable_id)
    comment_thread.json_comments
  end
end

post '/api/v1/:commentable_type/:commentable_id/comments' do |commentable_type, commentable_id|
  if commentable_id.to_i.to_s != commentable_id
    error 400, {:error => "commentable_id must be an integer"}.to_json
  else
    comment_thread = CommentThread.find_or_create_by_commentable_type_and_commentable_id(commentable_type, commentable_id)
    comment = comment_thread.super_comment.children.create :body => params[:body],
                                                           :title => params[:title],
                                                           :user_id => params[:user_id],
                                                           :course_id => params[:course_id]
    if comment.valid?
      comment.to_json
    else
      error 400, comment.errors.to_json
    end
  end
end
