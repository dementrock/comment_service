require 'active_record'
require 'ancestry'

class Comment < ActiveRecord::Base

  has_ancestry

  belongs_to :comment_thread

  def self.mock_comment
    create! :body => "here it is", :user_id => 0, :course_id => 0
  end

  def self.json_tree(nodes)
    nodes.map do |node, sub_nodes|
      node.to_json.merge(:children => json_tree(sub_nodes).compact)
    end.to_json
  end

  def to_json_tree
    self.class.json_tree(self.subtree.arrange)
  end

end
