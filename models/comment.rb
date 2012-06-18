require 'active_record'
require 'ancestry'

class Comment < ActiveRecord::Base

  attr_accessible :body, :title, :user_id, :course_id, :comment_thread

  has_ancestry

  belongs_to :comment_thread

  def self.hash_tree(nodes)
    nodes.map do |node, sub_nodes|
      {
        :body => node.body, 
        :title => node.title, 
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
