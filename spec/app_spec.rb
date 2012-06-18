require 'spec_helper'

describe "app" do
  before :each do
    Comment.delete_all
    CommentThread.delete_all
  end

  describe "GET on /api/v1/:commentable_type/:commentable_id/comments" do

    before :each do
      Comment.delete_all
      CommentThread.delete_all
    end

    it "should create a corresponding thread" do
      get '/api/v1/questions/1'
      last_response.should be_ok
      CommentThread.first.should_not be_nil
    end

    it "should create a corresponding thread with correct commentable type and commentable id" do
      get '/api/v1/questions/1'
      last_response.should be_ok
      CommentThread.first.commentable_type.should == 'questions'
      CommentThread.first.commentable_id.should == 1
    end

    it "should not create more than one thread for a single commentable" do
      get '/api/v1/quesitons/1'
      last_response.should be_ok
      get '/api/v1/quesitons/1'
      last_response.should be_ok
      CommentThread.count.should == 1
    end
  end
end
