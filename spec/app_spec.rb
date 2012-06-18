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
      comment_thread = CommentThread.first
      comment_thread.should_not be_nil
      comment_thread.super_comment.should_not be_nil
    end
    it "should create a corresponding comment thread with correct type and id" do
      get "/api/v1/questions/1/comments"
      last_response.should be_ok
      comment_thread = CommentThread.first
      comment_thread.commentable_type.should == 'questions'
      comment_thread.commentable_id.should == '1'
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
      comment = CommentThread.first.root_comments.first
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
      CommentThread.first.root_comments.create :body => "top comment", :title => "top", :user_id => 1, :course_id => 1
    end
    it "should create a sub comment with correct body, title, user_id, and course_id" do
      post "/api/v1/comment/#{CommentThread.first.root_comments.first.id}", 
           :body => "comment body", :title => "comment title", :user_id => 1, :course_id => 1
      last_response.should be_ok
      comment = CommentThread.first.root_comments.first.children.first
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
  describe "retrieve comments" do
    it "returns an empty array when there are no comments" do
      get "/api/v1/questions/1/comments"
      last_response.should be_ok
      comments = Yajl::Parser.parse last_response.body
      comments.length.should == 0
    end
    it "retrieves all comments in a nested structure in json format" do
      comment_thread = CommentThread.create! :commentable_type => "questions", :commentable_id => 1
      comment = []
      sub_comment = []
      comment << (comment_thread.root_comments.create :body => "top comment", :title => "top 0", :user_id => 1, :course_id => 1)
      sub_comment << (comment[0].children.create :body => "comment body", :title => "comment title 0", :user_id => 1, :course_id => 1)
      comment << (comment_thread.root_comments.create :body => "top comment", :title => "top 1", :user_id => 1, :course_id => 1)
      sub_comment << (comment[1].children.create :body => "comment body", :title => "comment title 1", :user_id => 1, :course_id => 1)
      get "/api/v1/questions/1/comments"
      last_response.should be_ok
      comments = Yajl::Parser.parse last_response.body
      comments.length.should == 2
      comments.each_with_index do |c, index|
        c["title"].should == "top #{index}"
        c["id"].should == comment[index].id
        c["reply_url"].should == "/api/v1/comment/#{comment[index].id}"
        c["children"].length.should == 1
        c["children"][0]["title"].should == "comment title #{index}"
        c["children"][0]["id"].should == sub_comment[index].id
        c["children"][0]["reply_url"].should == "/api/v1/comment/#{sub_comment[index].id}"
      end
    end
  end
  describe "delete comments" do
    before :each do
      comment_thread = CommentThread.create! :commentable_type => "questions", :commentable_id => 1
      comment = []
      sub_comment = []
      comment << (comment_thread.root_comments.create :body => "top comment", :title => "top 0", :user_id => 1, :course_id => 1)
      sub_comment << (comment[0].children.create :body => "comment body", :title => "comment title 0", :user_id => 1, :course_id => 1)
      comment << (comment_thread.root_comments.create :body => "top comment", :title => "top 1", :user_id => 1, :course_id => 1)
      sub_comment << (comment[1].children.create :body => "comment body", :title => "comment title 1", :user_id => 1, :course_id => 1)
    end
    it "should return error when called on a nonexisted thread" do
      delete "/api/v1/i_do_not_exist/1"
      last_response.status.should == 400
    end
    it "deletes all comments associated with a thread when called on the thread" do
      delete "/api/v1/questions/1"      
      last_response.should be_ok
      CommentThread.count.should == 0
      Comment.count.should == 0
    end
    it "deletes the comment and all sub comments when called on the comment" do
      comment_thread = CommentThread.first
      comment = comment_thread.comments.first
      delete "/api/v1/comment/#{comment.id}"
      CommentThread.root_comments.count.should == 1
      CommentThread.comments.count.should == 2
      CommentThread.root_comments.first.title.should == "top 1"
      CommentThread.root_comments.first.children.first.title.should == "comment title 1"
    end
  end
end
