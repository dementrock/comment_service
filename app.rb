require 'rubygems'
require 'yajl'
require 'active_record'
require 'sinatra'

require_relative 'models/comment'
require_relative 'models/comment_thread'


class Service < Sinatra::Base
  configure do
    env = ENV["SINATRA_ENV"] || "development"
    databases = YAML.load_file("config/database.yml")
    ActiveRecord::Base.establish_connection(databases[env])
  end

  before do
    content_type :json
  end

  get '/api/v1/:commentable_type/:commentable_id/comments' do
    comment_thread = CommentThread.find_or_create_by_commentable_type_and_commentable_id params[:commentable_type], params[:commentable_id]
    comment_thread.super
  end

end
