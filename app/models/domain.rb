class Domain < ActiveRecord::Base
  belongs_to :organization
  has_many :records

  after_save :log
  
  include ModelHelper

  def to_s
    "#{self.class}: #{self.name}"
  end

private
  def log
    EarLogger.instance.log self.to_s
  end

end
