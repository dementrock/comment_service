require 'active_record'
require 'ancestry'

class Comment < ActiveRecord::Base

  attr_accessible :body, :title, :user_id, :course_id, :comment_thread_id

  has_ancestry

  has_many :votes

  belongs_to :comment_thread

  def self.hash_tree(nodes)
    nodes.map do |node, sub_nodes|
      {
        :id => node.id,
        :body => node.body, 
        :title => node.title, 
        :reply_url => "/api/v1/comment/#{node.id}",
        :user_id => node.user_id, 
        :course_id => node.course_id,
        :children => hash_tree(sub_nodes).compact
      }
    end
  end

  def to_hash_tree
    self.class.hash_tree(self.subtree.arrange)
  end

end
