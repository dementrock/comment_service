require 'active_record'
require 'ancestry'

class Comment < ActiveRecord::Base

  has_ancestry

  belongs_to :comment_thread

  def self.mock_comment
    create! :body => "here it is", :user_id => 0, :course_id => 0
  end

end
