require 'active_record'

class CommentThread < ActiveRecord::Base
  
  has_one :super_comment, :class_name => "Comment", :dependent => :destroy

  # Ensures that each thread is associated with a commentable object
  validates_presence_of :commentable_type, :commentable_id

  # Ensures that there is only one thread for each commentable object
  validates_uniqueness_of :commentable_id, :scope => :commentable_type

  # Create a super comment which does not hold anything itself, but points to all comments of the thread
  after_create :create_super_comment
  
  def create_super_comment
    Comment.create! :comment_thread => self
  end

  def self.mock_comment_thread
    create! :body => "i dont understand",
            :title => "dont understand", 
            :user_id => 0,
            :course_id => 0,
            :commentable_type => "question",
            :commentable_id => 0
  end

end
