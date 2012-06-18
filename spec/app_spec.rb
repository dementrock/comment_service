require 'spec_helper'
require 'yajl'
require 'pp'

describe "app" do
  before :each do
    Comment.delete_all
    CommentThread.delete_all
  end
  describe "create empty thread on request" do
    it "should create a corresponding comment thread with a super comment" do
      get "/api/v1/questions/1/comments"
      last_response.should be_ok
      CommentThread.first.should_not be_nil
      CommentThread.first.super_comment.should_not be_nil
    end
    it "should create a corresponding comment thread with correct type and id" do
      get "/api/v1/questions/1/comments"
      last_response.should be_ok
      CommentThread.first.should_not be_nil
      CommentThread.first.commentable_type.should == 'questions'
      CommentThread.first.commentable_id.should == '1'
    end
    it "should return a 400 bad request if commentable_id is not an integer" do
      get "/api/v1/questions/a_question/comments"
      last_response.status.should == 400
    end
    it "should return an empty json when there are no comments" do
      get "/api/v1/questions/1/comments"
      last_response.should be_ok
      attributes = JSON.parse(last_response.body)
      attributes.length.should == 0
    end
  end
  describe "create top-level comments" do
    it "should create a top-level comment with correct body, title, user_id, and course_id" do
      post "/api/v1/questions/1/comments", :body => "comment body", :title => "comment title", :user_id => 1, :course_id => 1
      last_response.should be_ok
      comment = CommentThread.first.comments.first
      comment.should_not be_nil
      comment.body.should == "comment body"
      comment.title.should == "comment title"
      comment.user_id.should == 1
      comment.user_id.should == 1
    end
  end
  describe "create sub comments" do
    before :each do
      CommentThread.create! :commentable_type => "questions", :commentable_id => 1
      CommentThread.first.comments.create :body => "top comment", :title => "top", :user_id => 1, :course_id => 1
    end
    it "should create a sub comment with correct body, title, user_id, and course_id" do
      post "/api/v1/comment/#{CommentThread.first.comments.first.id}", 
           :body => "comment body", :title => "comment title", :user_id => 1, :course_id => 1
      last_response.should be_ok
      comment = CommentThread.first.comments.first.children.first
      comment.should_not be_nil
      comment.body.should == "comment body"
      comment.title.should == "comment title"
      comment.user_id.should == 1
      comment.user_id.should == 1
    end
    it "should not create a sub comment for the super comment" do
      post "/api/v1/comment/#{CommentThread.first.super_comment.id}", 
           :body => "comment body", :title => "comment title", :user_id => 1, :course_id => 1
      last_response.status.should == 400
    end
  end
  describe "retrive comments" do
    before :each do
      comment_thread = CommentThread.create! :commentable_type => "questions", :commentable_id => 1
      comment1 = comment_thread.comments.create :body => "top comment", :title => "top1", :user_id => 1, :course_id => 1
      sub_comment1 = comment1.children.create :body => "comment body", :title => "comment title 1", :user_id => 1, :course_id => 1
      comment2 = comment_thread.comments.create :body => "top comment", :title => "top2", :user_id => 1, :course_id => 1
      sub_comment2 = comment2.children.create :body => "comment body", :title => "comment title 2", :user_id => 1, :course_id => 1
    end
    it "retrives all comments in a nested structure in json format" do
      get "/api/v1/questions/1/comments"
      last_response.should be_ok
      comments = Yajl::Parser.parse last_response.body
      comments.length.should == 2
      comments[0]["title"].should == "top1"
      comments[0]["children"].length.should == 1
      comments[0]["children"][0]["title"].should == "comment title 1"
      comments[1]["title"].should == "top2"
      comments[1]["children"].length.should == 1
      comments[1]["children"][0]["title"].should == "comment title 2"
    end
  end
end
