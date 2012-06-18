require 'spec_helper'

describe "app" do

  before :each do
    Comment.delete_all
    CommentThread.delete_all
  end

  describe "GET on /api/v1/:commentable_type/:commentable_id/comments" do
    
    it "should create a corresponding comment thread with correct type and id" do
      get '/api/v1/questions/1/comments'
      last_response.should be_ok
      CommentThread.first.should_not be_nil
      CommentThread.first.commentable_type.should == 'questions'
      CommentThread.first.commentable_id.should == '1'
    end

    it "should return a 400 bad request if commentable_id is not an integer" do
      get '/api/v1/questions/a_question/comments'
      last_response.status.should == 400
    end

    it "should return an empty json when there are no comments" do
      get '/api/v1/questions/1/comments'
      last_response.should be_ok
      attributes = JSON.parse(last_response.body)
      attributes.length.should == 0
    end
  end
end
