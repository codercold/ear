class Host < ActiveRecord::Base
  has_many     :net_svcs
  has_many     :domains
  has_many     :task_runs
  has_many     :task_results, :through => :task_runs
  
  validates_uniqueness_of :ip_address
  validates_presence_of   :ip_address

  after_save   :log

  include ModelHelper

  def to_s
    "#{self.class}: #{self.ip_address}"
  end

private

  def log
    EarLogger.instance.log self.to_s
  end

end
