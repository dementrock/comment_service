require 'active_record'

class Voting < ActiveRecord::Base

  attr_accessible :up_vote, :user_id, :votable_type, :votable_id
  
end
